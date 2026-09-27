import { createHash } from "node:crypto";
import { deflateSync } from "node:zlib";

const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

const crcTable = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k += 1) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});

function crc32(data: Buffer): number {
  let crc = 0xffffffff;
  for (const byte of data) crc = crcTable[(crc ^ byte) & 0xff]! ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type: string, data: Buffer): Buffer {
  const name = Buffer.from(type, "ascii");
  const length = Buffer.allocUnsafe(4);
  length.writeUInt32BE(data.length);
  const checksum = Buffer.allocUnsafe(4);
  checksum.writeUInt32BE(crc32(Buffer.concat([name, data])));
  return Buffer.concat([length, name, data, checksum]);
}

export function makePaintingPng(width: number, height: number, seed: string): Buffer {
  const digest = createHash("sha256").update(seed).digest();
  const palette = Array.from({ length: 5 }, (_, i) => [digest[i * 3]!, digest[i * 3 + 1]!, digest[i * 3 + 2]!] as const);
  const raw = Buffer.allocUnsafe((width * 3 + 1) * height);
  const circles = Array.from({ length: 6 }, (_, i) => ({
    x: ((digest[15 + i]! / 255) * width) | 0,
    y: ((digest[21 + i]! / 255) * height) | 0,
    r: Math.max(35, ((digest[7 + i]! / 255) * Math.min(width, height) * 0.28) | 0),
    colour: palette[(i + 2) % palette.length]!,
  }));

  for (let y = 0; y < height; y += 1) {
    const row = y * (width * 3 + 1);
    raw[row] = 0;
    for (let x = 0; x < width; x += 1) {
      const band = Math.floor((x / width) * palette.length + (y / height) * 2) % palette.length;
      const base = palette[band]!;
      const wave = Math.sin((x + digest[0]!) / 47) * 22 + Math.cos((y + digest[1]!) / 61) * 18;
      let red = base[0] + wave;
      let green = base[1] + wave * 0.55;
      let blue = base[2] - wave * 0.35;
      for (const circle of circles) {
        const dx = x - circle.x;
        const dy = y - circle.y;
        if (dx * dx + dy * dy < circle.r * circle.r) {
          const mix = 0.58;
          red = red * (1 - mix) + circle.colour[0] * mix;
          green = green * (1 - mix) + circle.colour[1] * mix;
          blue = blue * (1 - mix) + circle.colour[2] * mix;
        }
      }
      const offset = row + 1 + x * 3;
      raw[offset] = Math.max(0, Math.min(255, red));
      raw[offset + 1] = Math.max(0, Math.min(255, green));
      raw[offset + 2] = Math.max(0, Math.min(255, blue));
    }
  }

  const ihdr = Buffer.allocUnsafe(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;
  return Buffer.concat([PNG_SIGNATURE, chunk("IHDR", ihdr), chunk("IDAT", deflateSync(raw, { level: 7 })), chunk("IEND", Buffer.alloc(0))]);
}
