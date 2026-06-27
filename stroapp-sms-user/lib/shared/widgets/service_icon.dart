import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

final Map<String, IconData> _brandIcons = {
  'telegram': FontAwesomeIcons.telegram,
  'whatsapp': FontAwesomeIcons.whatsapp,
  'google': FontAwesomeIcons.google,
  'google/gmail': FontAwesomeIcons.google,
  'google voice': FontAwesomeIcons.google,
  'google play': FontAwesomeIcons.googlePlay,
  'google business': FontAwesomeIcons.google,
  'facebook': FontAwesomeIcons.facebook,
  'facebook / meta': FontAwesomeIcons.facebook,
  'instagram': FontAwesomeIcons.instagram,
  'instagram / threads': FontAwesomeIcons.instagram,
  'twitter': FontAwesomeIcons.twitter,
  'twitter / x': FontAwesomeIcons.xTwitter,
  'tiktok': FontAwesomeIcons.tiktok,
  'discord': FontAwesomeIcons.discord,
  'snapchat': FontAwesomeIcons.snapchat,
  'uber': FontAwesomeIcons.uber,
  'amazon': FontAwesomeIcons.amazon,
  'netflix': Icons.live_tv,
  'linkedin': FontAwesomeIcons.linkedin,
  'microsoft': FontAwesomeIcons.microsoft,
  'apple': FontAwesomeIcons.apple,
  'airbnb': FontAwesomeIcons.airbnb,
  'signal': FontAwesomeIcons.signalMessenger,
  'viber': FontAwesomeIcons.viber,
  'line': FontAwesomeIcons.line,
  'wechat': FontAwesomeIcons.weixin,
  'steam': FontAwesomeIcons.steam,
  'yahoo': FontAwesomeIcons.yahoo,
  'tinder': Icons.favorite,
  'paypal': FontAwesomeIcons.paypal,
  'ebay': FontAwesomeIcons.ebay,
  'spotify': FontAwesomeIcons.spotify,
  'twitch': FontAwesomeIcons.twitch,
  'pinterest': FontAwesomeIcons.pinterest,
  'reddit': FontAwesomeIcons.reddit,
  'medium': FontAwesomeIcons.medium,
  'github': FontAwesomeIcons.github,
  'gitlab': FontAwesomeIcons.gitlab,
  'docker': FontAwesomeIcons.docker,
  'slack': FontAwesomeIcons.slack,
  'android': FontAwesomeIcons.android,
  'linux': FontAwesomeIcons.linux,
  'windows': FontAwesomeIcons.windows,
  'chrome': FontAwesomeIcons.chrome,
  'safari': FontAwesomeIcons.safari,
  'firefox': FontAwesomeIcons.firefox,
  'opera': FontAwesomeIcons.opera,
  'youtube': FontAwesomeIcons.youtube,
  'xbox': FontAwesomeIcons.xbox,
  'playstation': FontAwesomeIcons.playstation,
  'dropbox': FontAwesomeIcons.dropbox,
  'google drive': FontAwesomeIcons.googleDrive,
  'imdb': FontAwesomeIcons.imdb,
  'skype': FontAwesomeIcons.skype,
  'kakao': FontAwesomeIcons.kickstarterK,
  'coinbase': FontAwesomeIcons.bitcoin,
  'binance': FontAwesomeIcons.bitcoin,
  'cashapp': FontAwesomeIcons.moneyBillWave,
};

final Map<String, Color> _brandColors = {
  'telegram': const Color(0xFF0088CC),
  'whatsapp': const Color(0xFF25D366),
  'google': const Color(0xFF4285F4),
  'facebook': const Color(0xFF1877F2),
  'instagram': const Color(0xFFE4405F),
  'tiktok': const Color(0xFF010101),
  'twitter': const Color(0xFF1DA1F2),
  'discord': const Color(0xFF5865F2),
  'snapchat': const Color(0xFFFFFC00),
  'uber': const Color(0xFF000000),
  'amazon': const Color(0xFFFF9900),
  'netflix': const Color(0xFFE50914),
  'linkedin': const Color(0xFF0A66C2),
  'microsoft': const Color(0xFF00A4EF),
  'apple': const Color(0xFF000000),
  'airbnb': const Color(0xFFFF5A5F),
  'signal': const Color(0xFF3A76F0),
  'viber': const Color(0xFF7360F2),
  'line': const Color(0xFF00C300),
  'wechat': const Color(0xFF07C160),
  'steam': const Color(0xFF000000),
  'yahoo': const Color(0xFF6001D2),
  'tinder': const Color(0xFFFF6B6B),
  'paypal': const Color(0xFF003087),
  'ebay': const Color(0xFFE53238),
  'spotify': const Color(0xFF1DB954),
  'twitch': const Color(0xFF9146FF),
  'pinterest': const Color(0xFFE60023),
  'reddit': const Color(0xFFFF4500),
  'medium': const Color(0xFF000000),
  'github': const Color(0xFF181717),
  'gitlab': const Color(0xFFFC6D26),
  'docker': const Color(0xFF2496ED),
  'slack': const Color(0xFF4A154B),
  'android': const Color(0xFF3DDC84),
  'linux': const Color(0xFFFCC624),
  'windows': const Color(0xFF0078D6),
  'chrome': const Color(0xFF4285F4),
  'safari': const Color(0xFF006CFF),
  'firefox': const Color(0xFFFF7133),
  'opera': const Color(0xFFFF1B2D),
  'youtube': const Color(0xFFFF0000),
  'xbox': const Color(0xFF107C10),
  'playstation': const Color(0xFF003791),
  'dropbox': const Color(0xFF0061FF),
  'imdb': const Color(0xFFF5DE50),
  'skype': const Color(0xFF00AFF0),
  'kakao': const Color(0xFFFFE000),
  'coinbase': const Color(0xFF0052FF),
  'binance': const Color(0xFFF0B90B),
  'cashapp': const Color(0xFF00D632),
};

final Map<String, String> _domainMap = {
  'telegram': 'telegram.org',
  'whatsapp': 'whatsapp.com',
  'google': 'google.com',
  'facebook': 'facebook.com',
  'instagram': 'instagram.com',
  'twitter': 'twitter.com',
  'tiktok': 'tiktok.com',
  'discord': 'discord.com',
  'snapchat': 'snapchat.com',
  'uber': 'uber.com',
  'amazon': 'amazon.com',
  'netflix': 'netflix.com',
  'linkedin': 'linkedin.com',
  'microsoft': 'microsoft.com',
  'apple': 'apple.com',
  'airbnb': 'airbnb.com',
  'signal': 'signal.org',
  'viber': 'viber.com',
  'line': 'line.me',
  'wechat': 'wechat.com',
  'steam': 'steampowered.com',
  'yahoo': 'yahoo.com',
  'tinder': 'tinder.com',
  'paypal': 'paypal.com',
  'ebay': 'ebay.com',
  'spotify': 'spotify.com',
  'twitch': 'twitch.tv',
  'pinterest': 'pinterest.com',
  'reddit': 'reddit.com',
  'medium': 'medium.com',
  'github': 'github.com',
  'gitlab': 'gitlab.com',
  'docker': 'docker.com',
  'slack': 'slack.com',
  'coinbase': 'coinbase.com',
  'binance': 'binance.com',
  'kraken': 'kraken.com',
  'cashapp': 'cash.app',
  '1688': '1688.com',
  'imo': 'imo.im',
  'kakao': 'kakaocorp.com',
  'vkontakte': 'vk.com',
  'odnoklassniki': 'ok.ru',
  'openai': 'openai.com',
  'chatgpt': 'openai.com',
  'adobe': 'adobe.com',
  'authy': 'authy.com',
  'baidu': 'baidu.com',
  'agoda': 'agoda.com',
  'alibaba': 'alibaba.com',
  'allegro': 'allegro.pl',
  'avito': 'avito.ru',
  'backblaze': 'backblaze.com',
  'badoo': 'badoo.com',
  'bet365': 'bet365.com',
  'booking': 'booking.com',
  'careem': 'careem.com',
  'cdiscount': 'cdiscount.com',
  'cloudflare': 'cloudflare.com',
  'craigslist': 'craigslist.org',
  'daraz': 'daraz.com',
  'deezer': 'deezer.com',
  'deliveroo': 'deliveroo.com',
  'didi': 'didiglobal.com',
  'doordash': 'doordash.com',
  'duckduckgo': 'duckduckgo.com',
  'etsy': 'etsy.com',
  'fiverr': 'fiverr.com',
  'flipkart': 'flipkart.com',
  'freelancer': 'freelancer.com',
  'g2a': 'g2a.com',
  'getir': 'getir.com',
  'godaddy': 'godaddy.com',
  'gofundme': 'gofundme.com',
  'grab': 'grabtaxi.com',
  'groupon': 'groupon.com',
  'huawei': 'huawei.com',
  'icloud': 'icloud.com',
  'indeed': 'indeed.com',
  'jiji': 'jiji.ng',
  'jumia': 'jumia.com',
  'lazada': 'lazada.com',
  'letgo': 'letgo.com',
  'likee': 'likee.com',
  'lyft': 'lyft.com',
  'mercadolibre': 'mercadolibre.com',
  'messenger': 'messenger.com',
  'monzo': 'monzo.com',
  'mozilla': 'mozilla.org',
  'n26': 'n26.com',
  'naver': 'naver.com',
  'nextdoor': 'nextdoor.com',
  'nike': 'nike.com',
  'nintendo': 'nintendo.com',
  'notion': 'notion.so',
  'nubank': 'nubank.com.br',
  'olx': 'olx.com',
  'onet': 'onet.pl',
  'oracle': 'oracle.com',
  'outlook': 'outlook.com',
  'papara': 'papara.com',
  'patreon': 'patreon.com',
  'payoneer': 'payoneer.com',
  'paysera': 'paysera.com',
  'paysafecard': 'paysafecard.com',
  'proton': 'proton.me',
  'qq': 'qq.com',
  'rambler': 'rambler.ru',
  'revolut': 'revolut.com',
  'riot': 'riotgames.com',
  'robinhood': 'robinhood.com',
  'shopee': 'shopee.com',
  'skrill': 'skrill.com',
  'stripe': 'stripe.com',
  'talabat': 'talabat.com',
  'target': 'target.com',
  'temu': 'temu.com',
  'tesla': 'tesla.com',
  'ticketmaster': 'ticketmaster.com',
  'tinkoff': 'tinkoff.ru',
  'trello': 'trello.com',
  'tripadvisor': 'tripadvisor.com',
  'upwork': 'upwork.com',
  'venmo': 'venmo.com',
  'verizon': 'verizon.com',
  'walmart': 'walmart.com',
  'webex': 'webex.com',
  'weibo': 'weibo.com',
  'wise': 'wise.com',
  'wish': 'wish.com',
  'wordpress': 'wordpress.com',
  'xiaomi': 'xiaomi.com',
  'yandex': 'yandex.com',
  'zalo': 'zalo.me',
  'zalando': 'zalando.com',
  'zillow': 'zillow.com',
  'zoom': 'zoom.us',
};

IconData? _tryBrandIcon(String name) {
  final lower = name.toLowerCase().trim();
  for (final entry in _brandIcons.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

Color? _tryBrandColor(String name) {
  final lower = name.toLowerCase().trim();
  for (final entry in _brandColors.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

String _guessDomain(String name) {
  final lower = name.toLowerCase().trim();
  for (final entry in _domainMap.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }

  // Try first word after splitting by common separators
  final firstPart = lower.split(RegExp(r'[/|–—\-]')).first.trim();
  final words = firstPart.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  for (final word in words) {
    for (final entry in _domainMap.entries) {
      if (word.contains(entry.key)) return entry.value;
    }
  }

  if (words.isNotEmpty) {
    final cleaned = words.first.replaceAll(RegExp(r'[^a-z0-9.]'), '');
    if (cleaned.isNotEmpty) {
      if (cleaned.contains('.')) return cleaned;
      return '$cleaned.com';
    }
  }

  return 'example.com';
}

String _clearbitUrl(String name) {
  return 'https://logo.clearbit.com/${_guessDomain(name)}';
}

String _ddgIconUrl(String name) {
  return 'https://icons.duckduckgo.com/ip3/${_guessDomain(name)}.ico';
}

String _faviconUrl(String name) {
  return 'https://www.google.com/s2/favicons?domain=${_guessDomain(name)}&sz=64';
}

Color _avatarColor(String name) {
  final hash = name.hashCode;
  final hue = (hash % 360).abs().toDouble();
  return HSLColor.fromAHSL(0.7, hue, 0.6, 0.5).toColor();
}

String _avatarLetter(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed[0].toUpperCase();
}

class ServiceIcon extends StatelessWidget {
  final String serviceName;
  final double size;

  const ServiceIcon({
    super.key,
    required this.serviceName,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final brandIcon = _tryBrandIcon(serviceName);
    if (brandIcon != null) {
      final color = _tryBrandColor(serviceName) ?? Colors.black87;
      return Icon(brandIcon, size: size, color: color);
    }

    return _LogoWithFallback(
      serviceName: serviceName,
      size: size,
    );
  }
}

class _LogoWithFallback extends StatefulWidget {
  final String serviceName;
  final double size;

  const _LogoWithFallback({
    required this.serviceName,
    required this.size,
  });

  @override
  State<_LogoWithFallback> createState() => _LogoWithFallbackState();
}

class _LogoWithFallbackState extends State<_LogoWithFallback> {
  int _tried = 0;
  late final List<String> _urls;

  @override
  void initState() {
    super.initState();
    _urls = [
      _clearbitUrl(widget.serviceName),
      _ddgIconUrl(widget.serviceName),
      _faviconUrl(widget.serviceName),
    ];
  }

  void _tryNext() {
    _tried++;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_tried >= _urls.length) {
      return _AvatarFallback(
        serviceName: widget.serviceName,
        size: widget.size,
      );
    }

    return CachedNetworkImage(
      key: ValueKey('${widget.serviceName}_$_tried'),
      imageUrl: _urls[_tried],
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((__) => _tryNext());
        return const SizedBox.shrink();
      },
      placeholder: (_, __) => _AvatarFallback(
        serviceName: widget.serviceName,
        size: widget.size,
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String serviceName;
  final double size;

  const _AvatarFallback({
    required this.serviceName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _avatarColor(serviceName),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: FittedBox(
        child: Padding(
          padding: EdgeInsets.all(size * 0.15),
          child: Text(
            _avatarLetter(serviceName),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
