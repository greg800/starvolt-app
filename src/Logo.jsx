export default function Logo({ width = 140, color = 'white' }) {
  const iconW = Math.round(width * 0.28);
  const textSize = Math.round(width * 0.165);

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      {/* Star icon — 4-pointed star + 2 smaller accent stars */}
      <svg width={iconW} height={iconW} viewBox="0 0 48 48" fill="none">
        {/* Main 4-pointed star */}
        <path
          d="M24,3 C24,3 26.5,13.5 29.5,16.5 C32.5,19.5 45,22 45,22
             C45,22 32.5,24.5 29.5,27.5 C26.5,30.5 24,41 24,41
             C24,41 21.5,30.5 18.5,27.5 C15.5,24.5 3,22 3,22
             C3,22 15.5,19.5 18.5,16.5 C21.5,13.5 24,3 24,3 Z"
          fill={color}
        />
        {/* Upper-right small star */}
        <path
          d="M39,5 C39,5 40.2,9.5 41.8,11.2 C43.5,13 48,14 48,14
             C48,14 43.5,15 41.8,16.8 C40.2,18.5 39,23 39,23
             C39,23 37.8,18.5 36.2,16.8 C34.5,15 30,14 30,14
             C30,14 34.5,13 36.2,11.2 C37.8,9.5 39,5 39,5 Z"
          fill={color}
          opacity="0.85"
        />
        {/* Lower-left tiny star */}
        <path
          d="M9,31 C9,31 10,34.5 11.2,35.8 C12.5,37 16,37.5 16,37.5
             C16,37.5 12.5,38 11.2,39.2 C10,40.5 9,44 9,44
             C9,44 8,40.5 6.8,39.2 C5.5,38 2,37.5 2,37.5
             C2,37.5 5.5,37 6.8,35.8 C8,34.5 9,31 9,31 Z"
          fill={color}
          opacity="0.65"
        />
      </svg>

      {/* STARVOLT text */}
      <span
        style={{
          fontFamily: "'Poppins', sans-serif",
          fontWeight: 900,
          fontSize: textSize,
          color,
          letterSpacing: '0.06em',
          lineHeight: 1,
        }}
      >
        STARVOLT
      </span>
    </div>
  );
}
