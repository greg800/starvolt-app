import { useEffect } from 'react';
import confetti from 'canvas-confetti';

export default function Fireworks({ final = false }) {
  useEffect(() => {
    const colors = ['#7dd940', '#00c4c4', '#ffffff', '#ffd700', '#a3ed6a', '#0891b2'];
    const duration = final ? 5000 : 3000;
    const end = Date.now() + duration;

    const burst = () => {
      if (Date.now() > end) return;

      // Left burst
      confetti({
        particleCount: final ? 60 : 40,
        angle: 60,
        spread: 55,
        origin: { x: 0, y: 0.65 },
        colors,
        startVelocity: final ? 45 : 35,
        gravity: 0.85,
        scalar: 0.9,
        ticks: 180,
      });

      // Right burst
      confetti({
        particleCount: final ? 60 : 40,
        angle: 120,
        spread: 55,
        origin: { x: 1, y: 0.65 },
        colors,
        startVelocity: final ? 45 : 35,
        gravity: 0.85,
        scalar: 0.9,
        ticks: 180,
      });

      // Center random burst (final screen only)
      if (final) {
        confetti({
          particleCount: 30,
          spread: 360,
          origin: { x: Math.random(), y: Math.random() * 0.4 },
          colors,
          startVelocity: 20,
          gravity: 0.6,
          ticks: 160,
        });
      }

      requestAnimationFrame(burst);
    };

    // Initial big burst
    confetti({
      particleCount: final ? 120 : 80,
      spread: 80,
      origin: { x: 0.5, y: 0.55 },
      colors,
      startVelocity: 50,
      gravity: 0.9,
      scalar: 1,
      ticks: 220,
    });

    const handle = setTimeout(burst, 200);

    return () => clearTimeout(handle);
  }, [final]);

  return null;
}
