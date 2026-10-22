export default function AndroidIcon({ size = 38, ...props }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      aria-hidden="true"
      {...props}
    >
      <path
        fill="#3DDC84"
        d="M7 9h10v8.2a1.8 1.8 0 0 1-1.8 1.8H8.8A1.8 1.8 0 0 1 7 17.2V9Z"
      />
      <path fill="#3DDC84" d="M7.4 7.2a4.6 4.6 0 0 1 9.2 0H7.4Z" />
      <circle cx="9.4" cy="5.7" r=".8" fill="#0B0F17" />
      <circle cx="14.6" cy="5.7" r=".8" fill="#0B0F17" />
      <rect x="4.6" y="9.5" width="1.4" height="5" rx=".7" fill="#3DDC84" />
      <rect x="18" y="9.5" width="1.4" height="5" rx=".7" fill="#3DDC84" />
      <rect x="8.2" y="19" width="1.4" height="3" rx=".7" fill="#3DDC84" />
      <rect x="14.4" y="19" width="1.4" height="3" rx=".7" fill="#3DDC84" />
      <path
        stroke="#3DDC84"
        strokeWidth="1"
        strokeLinecap="round"
        d="m8.2 3.4 1.4 1.6M15.8 3.4l-1.4 1.6"
      />
    </svg>
  );
}
