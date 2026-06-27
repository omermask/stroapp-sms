"""اختبار شامل لمزامنة الخدمات والتسعير — الوحدات الجديدة"""
import asyncio
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.database import Base
from app.domain.models import (
    ServiceCountry, SyncLog, MarkupRule, gen_uuid,
)
from app.services.price_calculator import PriceCalculator
from app.services.sync_service import (
    SyncService, SyncOrchestrator, _normalize_country_name, _get_markup, _upsert_service_country,
)
from app.api.v1.admin_sync import MarkupRuleCreate, MarkupRuleUpdate


# ---------------------------------------------------------------------------
# Helper: in-memory SQLite DB
# ---------------------------------------------------------------------------

@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:", echo=False)
    Base.metadata.create_all(engine)
    TestSession = sessionmaker(bind=engine)
    session = TestSession()
    yield session
    session.close()
    Base.metadata.drop_all(engine)


# ===========================================================================
# 1. Model definitions
# ===========================================================================

class TestModels:

    def test_service_country_columns(self, db_session):
        r = ServiceCountry(
            id=gen_uuid(), service="telegram", country_code="US",
            provider="smspool", provider_cost=0.5, available_count=10,
            currency="USD", last_synced_at=datetime.now(timezone.utc),
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        )
        db_session.add(r)
        db_session.commit()
        assert r.id
        assert r.service == "telegram"
        assert r.country_code == "US"
        assert r.provider == "smspool"
        assert r.is_active is True

    def test_sync_log_columns(self, db_session):
        log = SyncLog(
            id=gen_uuid(), sync_type="all", status="running",
            triggered_by="manual", started_at=datetime.now(timezone.utc),
            created_at=datetime.now(timezone.utc),
        )
        db_session.add(log)
        db_session.commit()
        assert log.id
        assert log.sync_type == "all"

    def test_markup_rule_columns(self, db_session):
        rule = MarkupRule(
            id=gen_uuid(), service="telegram", country_code="US",
            markup_multiplier=1.5, priority=10, is_active=True,
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        )
        db_session.add(rule)
        db_session.commit()
        assert rule.id
        assert rule.markup_multiplier == 1.5

    def test_markup_rule_default_values(self, db_session):
        rule = MarkupRule(
            id=gen_uuid(),
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        )
        db_session.add(rule)
        db_session.commit()
        assert rule.markup_multiplier == 1.20
        assert rule.priority == 0
        assert rule.is_active is True
        assert rule.service is None
        assert rule.country_code is None

    def test_markup_rule_default_markup(self, db_session):
        rule = MarkupRule(
            id=gen_uuid(),
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        )
        db_session.add(rule)
        db_session.commit()
        assert rule.markup_multiplier == 1.20


# ===========================================================================
# 2. sync_service — _normalize_country_name
# ===========================================================================

class TestNormalizeCountry:

    def test_returns_iso_uppercase(self):
        assert _normalize_country_name("us") == "US"
        assert _normalize_country_name("  gb  ") == "GB"

    def test_known_name_to_iso(self):
        assert _normalize_country_name("United States") == "US"
        assert _normalize_country_name("المملكة المتحدة") == "GB"
        assert _normalize_country_name("الإمارات") == "AE"

    def test_invalid_returns_titlecased(self):
        assert _normalize_country_name("") == ""
        assert _normalize_country_name("XYZ") == "Xyz"  # .title() normalizes case


# ===========================================================================
# 3. sync_service — _get_markup
# ===========================================================================

class TestGetMarkup:

    def test_no_rules_returns_default(self, db_session):
        m = _get_markup(db_session, "telegram", "US", "smspool")
        assert m == 1.20

    def test_with_default_rule(self, db_session):
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=1.35, priority=0, is_active=True,
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.commit()
        m = _get_markup(db_session, "telegram", "US", "smspool")
        assert m == 1.35

    def test_specific_service_rule_wins(self, db_session):
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=2.0, priority=10, is_active=True,
            service="telegram",
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=1.5, priority=5, is_active=True,
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.commit()
        m = _get_markup(db_session, "telegram", "US", "smspool")
        assert m == 2.0

    def test_country_specific_rule(self, db_session):
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=2.5, priority=10, is_active=True,
            service="telegram", country_code="US",
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=1.0, priority=5, is_active=True,
            service="telegram",
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.commit()
        m = _get_markup(db_session, "telegram", "US", "smspool")
        assert m == 2.5

    def test_user_tier_rule(self, db_session):
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=3.0, priority=10, is_active=True,
            service="telegram", country_code="US", user_tier="premium",
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.commit()
        m = _get_markup(db_session, "telegram", "US", "smspool", user_tier="premium")
        assert m == 3.0

    def test_inactive_rules_ignored(self, db_session):
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=5.0, priority=99, is_active=False,
            service="telegram",
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=1.5, priority=0, is_active=True,
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.commit()
        m = _get_markup(db_session, "telegram", "US", "smspool")
        assert m == 1.5


# ===========================================================================
# 4. sync_service — _upsert_service_country
# ===========================================================================

class TestUpsertServiceCountry:

    def test_creates_new(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.5, 10)
        db_session.commit()
        count = db_session.query(ServiceCountry).count()
        assert count == 1

    def test_updates_existing(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.5, 10)
        db_session.commit()
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.75, 5)
        db_session.commit()
        r = db_session.query(ServiceCountry).first()
        assert r.provider_cost == 0.75
        assert r.available_count == 5

    def test_unique_constraint_keeps_one(self, db_session):
        _upsert_service_country(db_session, "x", "US", "p1", 1.0)
        _upsert_service_country(db_session, "x", "US", "p1", 2.0)
        db_session.commit()
        assert db_session.query(ServiceCountry).count() == 1


# ===========================================================================
# 5. PriceCalculator
# ===========================================================================

class TestPriceCalculator:

    def test_get_best_price_no_records(self, db_session):
        calc = PriceCalculator(db_session)
        result = calc.get_best_price("telegram", "US")
        assert result is None

    def test_get_best_price_one_record(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.5, 10)
        db_session.commit()
        calc = PriceCalculator(db_session)
        result = calc.get_best_price("telegram", "US")
        assert result is not None
        assert result["provider"] == "smspool"
        assert result["provider_cost"] == 0.5
        assert result["cost_coins"] > 0

    def test_get_best_price_picks_cheapest(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 2.0, 5)
        _upsert_service_country(db_session, "telegram", "US", "fivesim", 0.3, 20)
        _upsert_service_country(db_session, "telegram", "US", "smsactivate", 1.5, 10)
        db_session.commit()
        calc = PriceCalculator(db_session)
        result = calc.get_best_price("telegram", "US")
        assert result["provider"] == "fivesim"
        assert result["provider_cost"] == 0.3

    def test_get_best_price_ignores_inactive(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.1, 10)
        _upsert_service_country(db_session, "telegram", "US", "fivesim", 0.5, 20)
        db_session.commit()
        db_session.query(ServiceCountry).filter(ServiceCountry.provider == "smspool").update({"is_active": False})
        db_session.commit()
        calc = PriceCalculator(db_session)
        result = calc.get_best_price("telegram", "US")
        assert result["provider"] == "fivesim"

    def test_list_available(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.5, 10)
        _upsert_service_country(db_session, "telegram", "US", "fivesim", 0.3, 20)
        db_session.commit()
        calc = PriceCalculator(db_session)
        results = calc.list_available("telegram", "US")
        assert len(results) == 2
        assert results[0]["provider_cost"] == 0.3

    def test_get_services_with_prices(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.5, 10)
        _upsert_service_country(db_session, "whatsapp", "US", "fivesim", 0.3, 20)
        db_session.commit()
        calc = PriceCalculator(db_session)
        services = calc.get_services_with_prices("US")
        assert len(services) == 2
        svc_names = {s["service"] for s in services}
        assert "telegram" in svc_names
        assert "whatsapp" in svc_names

    def test_get_countries_for_service(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.5, 10)
        _upsert_service_country(db_session, "telegram", "GB", "fivesim", 0.4, 20)
        _upsert_service_country(db_session, "telegram", "DE", "smspool", 0.6, 5)
        db_session.commit()
        calc = PriceCalculator(db_session)
        countries = calc.get_countries_for_service("telegram")
        codes = {c["country_code"] for c in countries}
        assert "US" in codes
        assert "GB" in codes
        assert "DE" in codes

    def test_markup_applied_to_price(self, db_session):
        _upsert_service_country(db_session, "telegram", "US", "smspool", 0.5, 10)
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=2.0, priority=10, is_active=True,
            service="telegram", country_code="US",
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.commit()
        calc = PriceCalculator(db_session)
        result = calc.get_best_price("telegram", "US")
        assert result["markup"] == 2.0
        assert result["raw_price_usd"] == pytest.approx(1.0, rel=1e-3)


# ===========================================================================
# 6. Admin Sync Schemas
# ===========================================================================

class TestAdminSyncSchemas:

    def test_markup_rule_create(self):
        data = MarkupRuleCreate(
            service="telegram",
            country_code="US",
            provider="smspool",
            user_tier="premium",
            markup_multiplier=1.5,
            priority=5,
            description="Test rule",
        )
        assert data.service == "telegram"
        assert data.country_code == "US"
        assert data.markup_multiplier == 1.5

    def test_markup_rule_create_defaults(self):
        data = MarkupRuleCreate()
        assert data.markup_multiplier == 1.20
        assert data.priority == 0
        assert data.service is None

    def test_markup_rule_update(self):
        data = MarkupRuleUpdate(markup_multiplier=2.0, is_active=False)
        assert data.markup_multiplier == 2.0
        assert data.is_active is False
        assert data.priority is None


# ===========================================================================
# 7. SyncService — with mocked providers
# ===========================================================================

class TestSyncServiceMock:

    @pytest.mark.asyncio
    async def test_sync_all_mocked(self):
        svc = SyncService()
        mock_provider = MagicMock()
        mock_provider.name = "mock_test"
        mock_provider.get_countries = AsyncMock(return_value=[
            {"code": "US", "name": "United States"},
            {"code": "GB", "name": "United Kingdom"},
        ])
        mock_provider.get_services = AsyncMock(return_value=[
            MagicMock(service_id="telegram", cost=0.5, count=10, metadata={"country": "US"}),
            MagicMock(service_id="whatsapp", cost=0.3, count=20, metadata={"country": "GB"}),
        ])

        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.all.return_value = []
        mock_query = MagicMock()
        mock_query.filter.return_value.first.return_value = None
        mock_db.query.return_value = mock_query

        with patch("app.services.sync_service.SessionLocal", return_value=mock_db):
            with patch.object(svc, "_create_log") as mock_log:
                mock_log.return_value = MagicMock(id="log-1")
                with patch.object(svc, "_finalize_log"):
                    with patch("app.services.sync_service.provider_router") as mock_router:
                        mock_router.enabled_providers = [mock_provider]
                        result = await svc.sync_all(triggered_by="test")

        assert result["status"] == "success"
        assert "mock_test" in result["providers"]

    @pytest.mark.asyncio
    async def test_sync_stock_empty_records(self):
        svc = SyncService()
        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.all.return_value = []

        with patch("app.services.sync_service.SessionLocal", return_value=mock_db):
            with patch.object(svc, "_create_log") as mock_log:
                mock_log.return_value = MagicMock(id="log-1")
                with patch.object(svc, "_finalize_log"):
                    result = await svc.sync_stock(triggered_by="test")
        assert result["status"] == "success"


# ===========================================================================
# 8. SyncOrchestrator
# ===========================================================================

class TestSyncOrchestrator:

    @pytest.mark.asyncio
    async def test_start_stop(self):
        orch = SyncOrchestrator()
        assert orch._task is None
        orch.start(interval_seconds=99999)
        assert orch._task is not None
        assert not orch._task.done()
        orch.stop()
        await asyncio.sleep(0.1)
        assert orch._task.done()

    @pytest.mark.asyncio
    async def test_double_start(self):
        orch = SyncOrchestrator()
        orch.start(99999)
        task1 = orch._task
        orch.start(99999)
        assert orch._task is task1


# ===========================================================================
# 9. _resolve_markup (standalone in price_calculator)
# ===========================================================================

class TestResolveMarkupPriceCalculator:

    def test_default_markup_with_no_rules(self, db_session):
        from app.services.price_calculator import _resolve_markup
        m = _resolve_markup(db_session, "telegram", "US", "smspool")
        assert m == 1.20

    def test_default_rule_applied(self, db_session):
        from app.services.price_calculator import _resolve_markup
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=1.75, priority=5, is_active=True,
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.commit()
        m = _resolve_markup(db_session, "telegram", "US", "smspool")
        assert m == 1.75

    def test_specific_rule_wins_over_default(self, db_session):
        from app.services.price_calculator import _resolve_markup
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=3.0, priority=10, is_active=True,
            service="telegram",
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.add(MarkupRule(
            id=gen_uuid(), markup_multiplier=1.0, priority=0, is_active=True,
            created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc),
        ))
        db_session.commit()
        m = _resolve_markup(db_session, "telegram", "US", "smspool")
        assert m == 3.0
