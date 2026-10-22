export default function WindowsIcon({ size = 38, ...props }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      aria-hidden="true"
      {...props}
    >
      <path fill="#F25022" d="M3 3h8.2v8.2H3z" />
      <path fill="#7FBA00" d="M12.8 3H21v8.2h-8.2z" />
      <path fill="#00A4EF" d="M3 12.8h8.2V21H3z" />
      <path fill="#FFB900" d="M12.8 12.8H21V21h-8.2z" />
    </svg>
  );
}
