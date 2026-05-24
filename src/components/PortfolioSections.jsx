import React from 'react'
import D from '../data/portfolio'

const ACCENT_COLORS = {
  cyan: 'var(--cyan)',
  violet: 'var(--violet)',
  emerald: 'var(--emerald)',
  amber: 'var(--amber)',
  rose: 'var(--rose)',
}

export function Nav() {
  return (
    <nav className="nav">
      <div className="nav-inner">
        <div className="nav-brand">
          <span className="dot"></span>
          <span>guriboycodes</span>
        </div>
        <div className="nav-links">
          <a href="#work">Work</a>
          <a href="#brain">Ask My Brain</a>
          <a href="#xp">Experience</a>
          <a href="#skills">Skills</a>
        </div>
        <a className="nav-cta" href="#contact">Get in touch</a>
      </div>
    </nav>
  )
}

export function Hero() {
  const h = D.hero
  return (
    <section className="hero wrap">
      <div className="hero-grid">
        <div>
          <div className="eyebrow">{h.title}</div>
          <h1 className="hero-name">
            Gurinder<br />
            <span className="ital">Singh.</span>
          </h1>
          <p className="hero-pitch">"{h.pitch}"</p>
          <p className="hero-pitch-alt">{h.pitchAlt}</p>
          <div className="hero-meta">
            <span><span className="live-dot"></span>Available · NYC</span>
            <span>·</span>
            <span>2026 application: Sr Staff, Applied AI/ML</span>
          </div>
        </div>
        <div className="hero-portrait">
          <img src={h.portrait} className="ghibli" alt="Gurinder Singh, Ghibli style" />
          <img src={h.portraitAlt} className="alt" alt="Gurinder paragliding" />
          <div className="hero-portrait-meta">
            <span>Studio Ghibli · 2026</span>
            <span>hover →</span>
          </div>
        </div>
      </div>
    </section>
  )
}

export function Stats() {
  return (
    <div className="wrap">
      <div className="stats">
        {D.stats.map((s, i) => (
          <div className="stat" key={i}>
            <div className="stat-value">{s.value}</div>
            <div className="stat-label">{s.label}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

export function Flagship() {
  return (
    <section className="bay" id="work">
      <div className="wrap">
        <div className="eyebrow">2026 · Load-bearing systems</div>
        <h2 className="section-title">
          Five systems I authored<br />
          in the last <em>six months</em>.
        </h2>
        <p style={{ color: 'var(--text-2)', maxWidth: '62ch', fontSize: 16, lineHeight: 1.7 }}>
          Across MAIA, claude-cosmos, Vireo, Darwin, and Mac-in-a-Mac — productionized, cross-BU, named senior sponsorship. The work that took 84–89-day Venmo onboarding to a 20-minute demo, and unified a PayPal-wide program three weeks later.
        </p>

        <div className="flagship-list">
          {D.flagship.map((f, i) => (
            <FlagshipCard f={f} idx={i} key={f.id} />
          ))}
        </div>
      </div>
    </section>
  )
}

function FlagshipCard({ f, idx }) {
  const accent = ACCENT_COLORS[f.accent] || 'var(--cyan)'
  return (
    <article className="flagship" id={`f-${f.id}`} style={{ '--accent-c': accent }}>
      <div className="flagship-head">
        <div className="flagship-num" style={{ color: accent }}>0{idx + 1}</div>
        <div className="flagship-title-row">
          <div className="flagship-codename">
            <span style={{ color: accent, letterSpacing: '0.1em' }}>{f.codename}</span>
            <span className="pill live">{f.status}</span>
            {f.stamp && <span className="pill">{f.stamp}</span>}
          </div>
          <h3 className="flagship-title">
            {f.title.split(/(in three weeks|capture layer|workflows|judge|substrate)/).map((part, k) =>
              /three weeks|capture layer|workflows|judge|substrate/.test(part)
                ? <span className="ital" key={k}>{part}</span>
                : part
            )}
          </h3>
        </div>
        <div className="flagship-window">{f.window}</div>
      </div>
      <div className="flagship-body">
        <div>
          <p className="flagship-tagline">"{f.tagline}"</p>
          <p className="flagship-story">{f.story}</p>
          <p className="flagship-sponsor"><span className="label">Sponsored by:</span> {f.sponsor}</p>
          <div className="flagship-stack">
            {f.stack.map((s, k) => <span className="chip" key={k}>{s}</span>)}
          </div>
          {f.vocabulary && (
            <div className="flagship-vocab">
              {f.vocabulary.map((v, k) => <span className="vchip" key={k}>{v}</span>)}
            </div>
          )}
        </div>
        <div className="flagship-metrics">
          {f.metrics.map((m, k) => (
            <div className="metric" key={k}>
              <div className="metric-k">{m.k}</div>
              <div className="metric-v">{m.v}</div>
            </div>
          ))}
        </div>
      </div>
    </article>
  )
}

export function Experience() {
  return (
    <section className="bay" id="xp">
      <div className="wrap">
        <div className="eyebrow">Career arc</div>
        <h2 className="section-title">
          A decade<br />
          shipping at <em>scale.</em>
        </h2>
        <div className="timeline">
          {D.experience.map((x, i) => (
            <div className="t-item" key={i}>
              <div className="t-head">
                <div className="t-co">
                  <div className="t-logo"><img src={x.logo} alt={x.company} /></div>
                  <div>
                    <div className="t-company">{x.company}</div>
                    <div className="t-role">{x.role}</div>
                  </div>
                </div>
                <div className="t-window">{x.window}</div>
              </div>
              <ul className="t-bullets">
                {x.bullets.map((b, k) => <li key={k}>{b}</li>)}
              </ul>
            </div>
          ))}
        </div>

        <div className="eyebrow" style={{ marginTop: 80 }}>Hackathons · 28+ across 6+ countries</div>
        <h3 className="section-title" style={{ fontSize: 'clamp(28px, 4vw, 44px)' }}>
          Two <em>first-place wins</em>, judged at Yale.
        </h3>
        <div className="hacks">
          {D.hackathons.map((h, i) => (
            <div className="hack" key={i}>
              <div>
                <span className="hack-place">{h.place}</span>
                <span className="hack-flag">{h.flag}</span>
              </div>
              <div className="hack-name">{h.name}</div>
              <div className="hack-year">{h.year}</div>
              <div className="hack-desc">{h.desc}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

export function Skills() {
  return (
    <section className="bay" id="skills">
      <div className="wrap">
        <div className="eyebrow">Stack · 2026</div>
        <h2 className="section-title">
          The tools<br />
          I reach for <em>first.</em>
        </h2>
        <div className="skills-cols">
          {D.skills.map((g, i) => (
            <div className="skill-col" key={i}>
              <div className="skill-group">{g.group}</div>
              <div className="skill-list">
                {g.items.map((it, k) => (
                  <div className="skill-item" key={k}>
                    <img src={it.icon} alt="" />
                    <span>{it.name}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

export function Footer() {
  return (
    <section className="bay" id="contact">
      <div className="wrap">
        <div className="footer-grid">
          <div className="footer-pitch">
            Let's build the <em>infra</em> for what ships next.
          </div>
          <div className="footer-col">
            <h4>Contact</h4>
            <a href="mailto:gsingh622@yahoo.com">gsingh622@yahoo.com</a>
            <a href="mailto:gurisingh@paypal.com">gurisingh@paypal.com</a>
          </div>
          <div className="footer-col">
            <h4>Elsewhere</h4>
            <a href="https://github.com/Ripnrip" target="_blank" rel="noopener">GitHub</a>
            <a href="#" target="_blank">LinkedIn</a>
            <a href="#" target="_blank">Portfolio v0</a>
          </div>
        </div>
        <div className="footer-mini">
          <span>© 2026 Gurinder Singh · NYC</span>
          <span>Built with care · 2026 update</span>
        </div>
      </div>
    </section>
  )
}
