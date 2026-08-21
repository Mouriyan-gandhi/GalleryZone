"""Regenerates the launcher-icon and splash source images.

The four PNGs in this folder are build inputs, not hand-drawn artwork, so they
live here as generated output with this script as their source. Run it from
the project root, then re-run both generators:

    python assets/icon/generate_icons.py
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create

Why a `GZ` monogram and not `frontend-web/public/brand/gz-logo-mark.png`: that
file is a wide wordmark on white, carrying a finely-detailed India map inside
the `G`. At 48dp it is an unreadable smudge, and its white field fights a
dark-first brand. The monogram is the same mark the app already shows on its
own login crest, so the icon and the first screen agree.

Requires Pillow. Georgia Bold Italic stands in for the app's Playfair Display
italic — `google_fonts` fetches Playfair at runtime, so there is no local TTF
to render from here.
"""

from PIL import Image, ImageDraw, ImageFont

BG = (11, 10, 8, 255)  # AppColors.darkBackground
GOLD = (200, 154, 74)  # AppColors.darkGold
GOLD_BRIGHT = (233, 197, 122)  # AppColors.darkGoldBright
FONT = "C:/Windows/Fonts/georgiaz.ttf"
SIZE = 1024

_probe = ImageDraw.Draw(Image.new("L", (8, 8)))


def gold_gradient(size: int) -> Image.Image:
    """Vertical gold ramp, bright at the top — the direction the web's
    `from-gold-bright to-gold` buttons use."""
    grad = Image.new("RGB", (1, size))
    for y in range(size):
        t = y / max(1, size - 1)
        grad.putpixel(
            (0, y),
            tuple(round(GOLD_BRIGHT[i] + (GOLD[i] - GOLD_BRIGHT[i]) * t) for i in range(3)),
        )
    return grad.resize((size, size))


def monogram(size: int, box_ratio: float) -> Image.Image:
    """Transparent RGBA of a gold `GZ` whose ink spans `box_ratio` of the
    width. The point size is derived from one measurement rather than searched
    for — the glyph box scales linearly with it."""
    reference = 200
    left, _, right, _ = _probe.textbbox(
        (0, 0), "GZ", font=ImageFont.truetype(FONT, reference)
    )
    points = max(8, round(reference * (size * box_ratio) / (right - left)))

    font = ImageFont.truetype(FONT, points)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    left, top, right, bottom = draw.textbbox((0, 0), "GZ", font=font)
    draw.text(
        ((size - (right - left)) / 2 - left, (size - (bottom - top)) / 2 - top),
        "GZ",
        font=font,
        fill=255,
    )

    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(gold_gradient(size), (0, 0), mask)
    return out


def main() -> None:
    # Legacy square icon: monogram on the brand black.
    icon = Image.new("RGBA", (SIZE, SIZE), BG)
    icon.alpha_composite(monogram(SIZE, 0.62))
    icon.save("assets/icon/app_icon.png")

    # Adaptive foreground: transparent and smaller. Android composites it over
    # the flat background colour and masks the pair to the launcher's shape,
    # and only the centre ~66% is guaranteed to survive that mask.
    monogram(SIZE, 0.42).save("assets/icon/app_icon_foreground.png")

    # Splash. Android 12+ masks the splash icon to a circle showing only the
    # inner two-thirds, so it gets its own tighter version rather than a
    # scaled copy of the wider one.
    monogram(SIZE, 0.52).save("assets/icon/splash.png")
    monogram(SIZE, 0.34).save("assets/icon/splash_android12.png")


if __name__ == "__main__":
    main()
