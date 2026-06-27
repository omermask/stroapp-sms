from datetime import datetime, timezone, timedelta
import socket
import struct

import httpx
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.logging import get_logger
from app.domain.models import GeoIPCache, CarrierLookupCache, gen_uuid

logger = get_logger(__name__)


class GeoService:
    @staticmethod
    def _ip_to_int(ip: str) -> int:
        try:
            return struct.unpack("!I", socket.inet_aton(ip))[0]
        except OSError:
            return 0

    @staticmethod
    def _is_private_ip(ip: str) -> bool:
        ip_int = GeoService._ip_to_int(ip)
        ranges = [
            (0x0A000000, 0x0AFFFFFF),
            (0xAC100000, 0xAC1FFFFF),
            (0xC0A80000, 0xC0A8FFFF),
            (0x7F000000, 0x7FFFFFFF),
        ]
        for start, end in ranges:
            if start <= ip_int <= end:
                return True
        return False

    @staticmethod
    async def lookup_ip(db: Session, ip_address: str) -> dict:
        if GeoService._is_private_ip(ip_address):
            return {"ip": ip_address, "country": "Private", "city": "", "is_proxy": False}

        cached = db.query(GeoIPCache).filter(
            GeoIPCache.ip_address == ip_address,
            GeoIPCache.expires_at > datetime.now(timezone.utc),
        ).first()
        if cached:
            return {"ip": cached.ip_address, "country": cached.country,
                    "city": cached.city, "region": cached.region,
                    "isp": cached.isp, "is_proxy": cached.is_proxy,
                    "latitude": cached.latitude, "longitude": cached.longitude}

        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(f"http://ip-api.com/json/{ip_address}")
                if resp.status_code == 200:
                    data = resp.json()
                    entry = GeoIPCache(
                        id=gen_uuid(),
                        ip_address=ip_address,
                        country=data.get("country", ""),
                        city=data.get("city", ""),
                        region=data.get("regionName", ""),
                        isp=data.get("isp", ""),
                        is_proxy=data.get("proxy", False),
                        latitude=data.get("lat"),
                        longitude=data.get("lon"),
                        expires_at=datetime.now(timezone.utc) + timedelta(days=30),
                    )
                    db.add(entry)
                    db.commit()
                    return {"ip": ip_address, "country": entry.country,
                            "city": entry.city, "region": entry.region,
                            "isp": entry.isp, "is_proxy": entry.is_proxy,
                            "latitude": entry.latitude, "longitude": entry.longitude}
        except Exception as e:
            logger.warning(f"GeoIP lookup error for {ip_address}: {e}")

        return {"ip": ip_address, "country": "Unknown", "city": "", "is_proxy": False}

    @staticmethod
    async def lookup_carrier(db: Session, phone_number: str) -> dict:
        cached = db.query(CarrierLookupCache).filter(
            CarrierLookupCache.phone_number == phone_number,
            CarrierLookupCache.expires_at > datetime.now(timezone.utc),
        ).first()
        if cached:
            return {"phone": cached.phone_number, "carrier": cached.carrier,
                    "country_code": cached.country_code, "network_type": cached.network_type,
                    "is_voip": cached.is_voip, "is_prepaid": cached.is_prepaid}

        result = {"phone": phone_number, "carrier": "", "country_code": "",
                  "network_type": "", "is_voip": False, "is_prepaid": False}

        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(
                    f"https://phonevalidation.abstractapi.com/v1/",
                    params={"phone": phone_number, "api_key": get_settings().abstractapi_key or ""},
                )
                if resp.status_code == 200:
                    data = resp.json()
                    result["carrier"] = data.get("carrier", "")
                    result["country_code"] = data.get("country_code", "")
                    result["network_type"] = data.get("line_type", "")
        except Exception as e:
            logger.warning(f"Carrier lookup error for {phone_number}: {e}")

        entry = CarrierLookupCache(
            id=gen_uuid(),
            phone_number=phone_number,
            carrier=result["carrier"],
            country_code=result["country_code"],
            network_type=result["network_type"],
            is_voip=result["is_voip"],
            is_prepaid=result["is_prepaid"],
            expires_at=datetime.now(timezone.utc) + timedelta(days=7),
        )
        db.add(entry)
        db.commit()
        return result
