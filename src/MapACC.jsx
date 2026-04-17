export default function MapACC({ name = 'Marie' }) {
  return (
    <div className="map-container">
      <svg
        viewBox="0 0 320 210"
        style={{ width: '100%', display: 'block' }}
        aria-label={`Carte ACC Lyon — logement de ${name} et site photovoltaïque dans un rayon de 2km`}
      >
        <defs>
          {/* Map gradient background */}
          <linearGradient id="mapGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%"   stopColor="#064e5e" />
            <stop offset="100%" stopColor="#0a7a6e" />
          </linearGradient>

          {/* Grid pattern */}
          <pattern id="grid" width="24" height="24" patternUnits="userSpaceOnUse">
            <path
              d="M 24 0 L 0 0 0 24"
              fill="none"
              stroke="rgba(255,255,255,0.07)"
              strokeWidth="0.6"
            />
          </pattern>

          {/* Glow filter for icons */}
          <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="3" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          {/* Green glow for circle */}
          <filter id="greenGlow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur stdDeviation="4" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          {/* Clip map to rounded rect */}
          <clipPath id="mapClip">
            <rect width="320" height="210" rx="16" />
          </clipPath>
        </defs>

        <g clipPath="url(#mapClip)">
          {/* Background */}
          <rect width="320" height="210" fill="url(#mapGrad)" />
          <rect width="320" height="210" fill="url(#grid)" />

          {/* Abstract street network */}
          {/* Main roads */}
          <line x1="0" y1="105" x2="320" y2="105" stroke="rgba(255,255,255,0.12)" strokeWidth="3" />
          <line x1="160" y1="0" x2="160" y2="210" stroke="rgba(255,255,255,0.12)" strokeWidth="3" />
          {/* Secondary roads */}
          <line x1="0" y1="52"  x2="320" y2="52"  stroke="rgba(255,255,255,0.07)" strokeWidth="1.5" />
          <line x1="0" y1="158" x2="320" y2="158" stroke="rgba(255,255,255,0.07)" strokeWidth="1.5" />
          <line x1="80"  y1="0" x2="80"  y2="210" stroke="rgba(255,255,255,0.07)" strokeWidth="1.5" />
          <line x1="240" y1="0" x2="240" y2="210" stroke="rgba(255,255,255,0.07)" strokeWidth="1.5" />
          {/* Diagonal — gives a Lyon Presqu'île feel */}
          <line x1="0"   y1="20"  x2="120" y2="105" stroke="rgba(255,255,255,0.05)" strokeWidth="1.5" />
          <line x1="200" y1="105" x2="320" y2="185" stroke="rgba(255,255,255,0.05)" strokeWidth="1.5" />
          <line x1="40"  y1="0"   x2="160" y2="80"  stroke="rgba(255,255,255,0.05)" strokeWidth="1" />

          {/* 2km zone fill */}
          <circle
            cx="155" cy="110"
            r="82"
            fill="rgba(125, 217, 64, 0.06)"
            stroke="none"
          />

          {/* 2km dashed circle */}
          <circle
            cx="155" cy="110"
            r="82"
            fill="none"
            stroke="#7dd940"
            strokeWidth="1.8"
            strokeDasharray="7 4"
            opacity="0.85"
            filter="url(#greenGlow)"
          />

          {/* 2km label */}
          <rect x="128" y="20" width="54" height="18" rx="9" fill="rgba(125,217,64,0.2)" />
          <text
            x="155" y="32"
            textAnchor="middle"
            fill="#7dd940"
            fontSize="10"
            fontFamily="Poppins, sans-serif"
            fontWeight="700"
          >
            ⌀ 2 km
          </text>

          {/* Energy link between house and PV */}
          <line
            x1="148" y1="118"
            x2="205" y2="80"
            stroke="#7dd940"
            strokeWidth="1.5"
            strokeDasharray="5 4"
            opacity="0.55"
          />

          {/* Animated energy dot */}
          <circle r="3" fill="#7dd940" opacity="0.9">
            <animateMotion
              dur="2.5s"
              repeatCount="indefinite"
              path="M 205,80 L 148,118"
            />
          </circle>

          {/* ─── MAISON DE MARIE ─── */}
          <g transform="translate(126, 98)" filter="url(#glow)">
            {/* Glow halo */}
            <circle cx="14" cy="14" r="18" fill="rgba(255,255,255,0.12)" />
            {/* House body */}
            <rect x="4" y="13" width="20" height="14" rx="2" fill="white" opacity="0.95" />
            {/* Roof */}
            <polygon points="14,2 28,13 0,13" fill="white" opacity="0.95" />
            {/* Door */}
            <rect x="10" y="19" width="8" height="8" rx="1" fill="#0a9b8c" />
            {/* Window */}
            <rect x="4" y="16" width="5" height="5" rx="1" fill="#0a9b8c" opacity="0.7" />
          </g>
          <text
            x="140" y="137"
            textAnchor="middle"
            fill="white"
            fontSize="9"
            fontFamily="Poppins, sans-serif"
            fontWeight="600"
            opacity="0.9"
          >
            Chez {name}
          </text>

          {/* ─── SITE PV ─── */}
          <g transform="translate(191, 63)" filter="url(#glow)">
            {/* Glow halo */}
            <circle cx="14" cy="14" r="18" fill="rgba(255,220,0,0.15)" />
            {/* Sun circle */}
            <circle cx="14" cy="14" r="7" fill="#ffd700" />
            {/* Sun rays */}
            <line x1="14" y1="2"  x2="14" y2="6"  stroke="#ffd700" strokeWidth="2" strokeLinecap="round" />
            <line x1="14" y1="22" x2="14" y2="26" stroke="#ffd700" strokeWidth="2" strokeLinecap="round" />
            <line x1="2"  y1="14" x2="6"  y2="14" stroke="#ffd700" strokeWidth="2" strokeLinecap="round" />
            <line x1="22" y1="14" x2="26" y2="14" stroke="#ffd700" strokeWidth="2" strokeLinecap="round" />
            <line x1="5"  y1="5"  x2="8"  y2="8"  stroke="#ffd700" strokeWidth="1.5" strokeLinecap="round" />
            <line x1="20" y1="20" x2="23" y2="23" stroke="#ffd700" strokeWidth="1.5" strokeLinecap="round" />
            <line x1="23" y1="5"  x2="20" y2="8"  stroke="#ffd700" strokeWidth="1.5" strokeLinecap="round" />
            <line x1="8"  y1="20" x2="5"  y2="23" stroke="#ffd700" strokeWidth="1.5" strokeLinecap="round" />
          </g>
          <text
            x="205" y="96"
            textAnchor="middle"
            fill="white"
            fontSize="9"
            fontFamily="Poppins, sans-serif"
            fontWeight="600"
            opacity="0.9"
          >
            Site PV
          </text>

          {/* Lyon watermark */}
          <text
            x="12" y="200"
            fill="rgba(255,255,255,0.25)"
            fontSize="9"
            fontFamily="Poppins, sans-serif"
          >
            Lyon, France
          </text>

          {/* North indicator */}
          <text
            x="302" y="24"
            textAnchor="middle"
            fill="rgba(255,255,255,0.35)"
            fontSize="11"
            fontFamily="Poppins, sans-serif"
            fontWeight="700"
          >
            N
          </text>
          <line x1="302" y1="26" x2="302" y2="36" stroke="rgba(255,255,255,0.25)" strokeWidth="1" />
        </g>
      </svg>
    </div>
  );
}
