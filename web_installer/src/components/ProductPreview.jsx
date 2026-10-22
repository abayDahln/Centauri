const bars = [38, 52, 44, 68, 58, 82, 72, 94];

export default function ProductPreview() {
  return (
    <div className="preview-wrap" aria-hidden="true" dir="ltr">
      <div className="preview-glow" />

      <div className="preview-window">
        <div className="preview-bar">
          <span className="dot dot-red" />
          <span className="dot dot-yellow" />
          <span className="dot dot-green" />
          <span className="preview-url">centauri.app / preview</span>
          <span className="preview-badge">Live</span>
        </div>

        <div className="preview-body">
          <aside className="preview-chat">
            <div className="chat-head">
              <span className="chat-avatar">C</span>
              <span>Alpha</span>
              <span className="chat-online" />
            </div>

            <div className="chat-bubble user">
              Build an analytics dashboard with a sidebar, stat cards, and a
              sales chart.
            </div>

            <div className="chat-bubble ai">
              <span className="ai-spark">✦</span> Ready. I&apos;ll create 3
              pages: overview, reports, and settings.
            </div>

            <div className="chat-typing">
              <span />
              <span />
              <span />
            </div>
          </aside>

          <div className="preview-canvas">
            <div className="mock-app">
              <aside className="mock-sidebar">
                <div className="mock-logo">
                  <span className="mock-logo-mark">C</span>
                  <span>Centauri</span>
                </div>
                <div className="mock-nav">
                  <span className="active" />
                  <span />
                  <span />
                  <span />
                </div>
                <div className="mock-sidebar-foot" />
              </aside>

              <div className="mock-main">
                <div className="mock-top">
                  <div>
                    <span className="mock-kicker">Dashboard</span>
                    <span className="mock-title">Overview</span>
                  </div>
                  <span className="mock-avatar" />
                </div>

                <div className="mock-stats">
                  <div className="mock-stat">
                    <span>Revenue</span>
                    <strong>$48.2k</strong>
                    <small className="up">+12.4%</small>
                  </div>
                  <div className="mock-stat">
                    <span>Active users</span>
                    <strong>12,840</strong>
                    <small className="up">+8.1%</small>
                  </div>
                  <div className="mock-stat">
                    <span>Conversion</span>
                    <strong>4.7%</strong>
                    <small className="down">-0.3%</small>
                  </div>
                </div>

                <div className="mock-chart">
                  <div className="mock-chart-head">
                    <span>Sales</span>
                    <span className="mock-chip">6 months</span>
                  </div>
                  <div className="mock-bars">
                    {bars.map((height, index) => (
                      <span
                        key={index}
                        style={{
                          height: `${height}%`,
                          animationDelay: `${index * 90}ms`,
                        }}
                      />
                    ))}
                  </div>
                </div>

                <div className="mock-table">
                  <div className="mock-row">
                    <span>Pro plan</span>
                    <span>$12.4k</span>
                    <span>+18%</span>
                  </div>
                  <div className="mock-row">
                    <span>Team plan</span>
                    <span>$8.1k</span>
                    <span>+9%</span>
                  </div>
                  <div className="mock-row">
                    <span>Starter</span>
                    <span>$3.6k</span>
                    <span>+4%</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="preview-float preview-float-a">
        <span className="float-icon">✦</span>
        <div>
          <strong>Fluid</strong>
          <span>Every screen size</span>
        </div>
      </div>

      <div className="preview-float preview-float-b">
        <span className="float-icon">↗</span>
        <div>
          <strong>Export</strong>
          <span>HTML · React · Figma</span>
        </div>
      </div>
    </div>
  );
}
