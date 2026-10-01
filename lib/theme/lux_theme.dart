import 'package:flutter/material.dart';
import '../services/cart_service.dart';

/// Electra Hardware — premium dark-luxury design system.
///
/// Dark charcoal / black / deep brown surfaces, champagne-gold accents,
/// white + soft-grey typography. The finalized red/white Login screen is
/// untouched; everything else derives its DNA (spacing, rhythm, 55px
/// primary buttons, 12-16px radii) from it, dressed in this theme.
class LuxColors {
  LuxColors._();

  static const Color background = Color(0xFF0B0B0B);
  static const Color surface = Color(0xFF101010);
  static const Color card = Color(0xFF161616);
  static const Color cardElevated = Color(0xFF1E1E1E);
  static const Color cardGlass = Color(0xB3161616);

  static const Color gold = Color(0xFFC9A45C);
  static const Color goldLight = Color(0xFFE9CB8B);
  static const Color goldDeep = Color(0xFF8A6A2F);
  static const Color goldTint = Color(0x24C9A45C);
  static const Color goldBorder = Color(0x55C9A45C);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA8A8A8);
  static const Color textMuted = Color(0xFF6E6E6E);

  static const Color divider = Color(0xFF232323);
  static const Color fieldFill = Color(0xFF161616);

  /// Electra brand red — logo accents only.
  static const Color electraRed = Color(0xFFD43D2A);

  static const Color success = Color(0xFF6FCF7B);
  static const Color info = Color(0xFF6AA9E8);
  static const Color warning = Color(0xFFE0B25C);
  static const Color danger = Color(0xFFE57373);
}

/// App-wide dark theme. Applied in main.dart only.
ThemeData luxThemeData() {
  const scheme = ColorScheme.dark(
    primary: LuxColors.gold,
    secondary: LuxColors.goldLight,
    surface: LuxColors.surface,
    error: LuxColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: LuxColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: LuxColors.background,
      foregroundColor: LuxColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: LuxColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LuxColors.cardElevated,
      contentTextStyle: TextStyle(color: LuxColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: LuxColors.cardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      titleTextStyle: TextStyle(
        color: LuxColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: LuxColors.textSecondary,
        fontSize: 15,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: LuxColors.cardElevated,
      selectedColor: LuxColors.gold,
      labelStyle: const TextStyle(color: LuxColors.textSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: LuxColors.divider),
      ),
    ),
    dividerColor: LuxColors.divider,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LuxColors.background,
      selectedItemColor: LuxColors.gold,
      unselectedItemColor: LuxColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}

/// Shared text styles.
class LuxText {
  LuxText._();

  static const TextStyle display = TextStyle(
    color: LuxColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.25,
  );
  static const TextStyle title = TextStyle(
    color: LuxColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
  static const TextStyle heading = TextStyle(
    color: LuxColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle body = TextStyle(
    color: LuxColors.textSecondary,
    fontSize: 15,
    height: 1.45,
  );
  static const TextStyle bodyStrong = TextStyle(
    color: LuxColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(
    color: LuxColors.textMuted,
    fontSize: 13,
  );
  static const TextStyle goldLabel = TextStyle(
    color: LuxColors.gold,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
  );
}

/// Premium dark app bar: transparent-black, white title, gold-tinted back.
class LuxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;

  const LuxAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: LuxColors.background,
      foregroundColor: LuxColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: LuxColors.textPrimary,
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null),
      title: Text(title, style: LuxText.heading.copyWith(fontSize: 19)),
      actions: actions,
    );
  }
}

/// Primary champagne-gold CTA — 55px like the finalized login button.
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: Color(0xFF1A1408),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: const Color(0xFF1A1408)),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF1A1408),
                ),
              ),
            ],
          );
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LuxColors.gold,
          foregroundColor: const Color(0xFF1A1408),
          disabledBackgroundColor: LuxColors.goldDeep,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Subtle gold-outline secondary button.
class LuxOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const LuxOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: LuxColors.gold,
          side: const BorderSide(color: LuxColors.goldBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smoked-glass card: translucent dark fill, hairline gold-tinted border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: LuxColors.cardGlass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: LuxColors.goldBorder, width: 0.8),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        splashColor: LuxColors.goldTint,
        highlightColor: LuxColors.goldTint,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Section header: title left, gold "action →" right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: LuxText.title.copyWith(fontSize: 19)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: LuxColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Dark search field with gold focus border.
class LuxSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const LuxSearchField({
    super.key,
    this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: LuxColors.textPrimary),
      cursorColor: LuxColors.gold,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: LuxColors.textMuted),
        prefixIcon: const Icon(Icons.search_rounded,
            color: LuxColors.textMuted),
        filled: true,
        fillColor: LuxColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LuxColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LuxColors.gold, width: 1.2),
        ),
      ),
    );
  }
}

/// Cart icon with live gold count badge (driven by CartService).
class CartBadgeButton extends StatelessWidget {
  final VoidCallback onTap;
  final double iconSize;

  const CartBadgeButton({
    super.key,
    required this.onTap,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final count = CartService.totalItems;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.shopping_cart_outlined,
                  size: iconSize, color: LuxColors.textPrimary),
              onPressed: onTap,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: LuxColors.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Color(0xFF1A1408),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Order status pill — semantic hues tuned for the dark theme.
class StatusBadge extends StatelessWidget {
  final String? status;

  const StatusBadge({super.key, this.status});

  Color get _color {
    switch (status?.toLowerCase()) {
      case 'pending':
        return LuxColors.gold;
      case 'confirmed':
      case 'approved':
        return LuxColors.success;
      case 'processing':
        return const Color(0xFFB388EB);
      case 'dispatched':
      case 'dispatch':
        return LuxColors.info;
      case 'delivered':
        return LuxColors.success;
      case 'cancelled':
        return LuxColors.danger;
      default:
        return LuxColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.45)),
      ),
      child: Text(
        status ?? 'Unknown',
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Elegant empty state.
class LuxEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const LuxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LuxColors.goldTint,
                border: Border.all(color: LuxColors.goldBorder),
              ),
              child: Icon(icon, size: 44, color: LuxColors.gold),
            ),
            const SizedBox(height: 20),
            Text(title, style: LuxText.title.copyWith(fontSize: 19),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: LuxText.body,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gold progress indicator.
class LuxLoader extends StatelessWidget {
  final double size;
  const LuxLoader({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        color: LuxColors.gold,
        strokeWidth: 2.8,
      ),
    );
  }
}

/// Logo on an ivory badge (the logo's script text is black, so it needs
/// a light surface on dark backgrounds).
class LogoBadge extends StatelessWidget {
  final double size;
  final double radius;

  const LogoBadge({super.key, this.size = 120, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EA),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: LuxColors.goldBorder, width: 1.2),
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
    );
  }
}

/// Elegant "coming soon" bottom sheet — pure UI placeholder for sections
/// with no backend yet (e.g. Invoices, O/S Payment). No data, no logic.
Future<void> showLuxComingSoon(BuildContext context, String title) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: LuxColors.cardElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: LuxColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxColors.goldTint,
              border: Border.all(color: LuxColors.goldBorder),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: LuxColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: LuxText.title.copyWith(fontSize: 19)),
          const SizedBox(height: 8),
          const Text(
            'This section is coming soon.\nOur team will notify you when it goes live.',
            textAlign: TextAlign.center,
            style: LuxText.body,
          ),
        ],
      ),
    ),
  );
}

/// Premium page transition: gentle fade + rise.
Route<T> luxRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final fade =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
