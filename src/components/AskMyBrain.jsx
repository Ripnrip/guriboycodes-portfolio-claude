import React, { useState, useEffect, useRef, useMemo } from 'react'
import D from '../data/portfolio'

const BRAIN = D.brain

/* tokenize + score corpus chunks against the query */
function tokenize(s) {
  return s.toLowerCase().replace(/[^a-z0-9 ]+/g, ' ').split(/\s+/).filter(t => t.length > 2)
}
const STOP = new Set(['the', 'and', 'for', 'you', 'what', 'tell', 'more', 'with', 'how', 'why', 'does', 'this', 'that', 'into', 'your', 'yours', 'about', 'much', 'were', 'was', 'are', 'have', 'has'])

function retrieve(query, k = 4) {
  const qTokens = tokenize(query).filter(t => !STOP.has(t))
  if (!qTokens.length) return []
  const scored = BRAIN.corpus.map(c => {
    const text = (c.text + ' ' + c.topic).toLowerCase()
    let score = 0
    for (const t of qTokens) {
      if (text.includes(t)) score += 2
      if (text.split(/\s+/).some(w => w.startsWith(t) && t.length > 3)) score += 0.5
    }
    return { ...c, score }
  })
  scored.sort((a, b) => b.score - a.score)
  return scored.filter(c => c.score > 0).slice(0, k)
}

/* Map topic → graph node IDs to highlight */
function activeNodesForSources(sources) {
  const topicMap = {
    'MAIA': ['maia', 'merchants', 'venmo'],
    'claude-cosmos': ['cosmos', 'mcp', 'devmo', 'agent0'],
    'Vireo': ['vireo', 'mcp', 'devmo'],
    'Darwin': ['darwin', 'gepa', 'fossils', 'cosmos'],
    'Mac-in-a-Mac': ['miam', 'agent0', 'livery'],
    'Venmo': ['venmo', 'patent', 'maia'],
    'Hackathons': [],
    'Earlier': [],
    'Sponsors': [],
    'Philosophy': [],
  }
  const ids = new Set()
  for (const s of sources) {
    (topicMap[s.topic] || []).forEach(id => ids.add(id))
  }
  return ids
}

function KnowledgeGraph({ activeIds, onHover }) {
  const W = 540, H = 540
  const PAD = 50

  const positions = useMemo(() => {
    const m = {}
    for (const n of BRAIN.nodes) {
      m[n.id] = {
        x: PAD + n.x * (W - 2 * PAD),
        y: PAD + n.y * (H - 2 * PAD),
      }
    }
    return m
  }, [])

  const kindColor = {
    system: 'var(--cyan)',
    program: 'var(--violet)',
    tech: 'var(--emerald)',
    metric: 'var(--amber)',
    milestone: 'var(--rose)',
  }

  const hasActive = activeIds && activeIds.size > 0
  const sizeFor = (n) => {
    if (n.kind === 'system') return 18
    if (n.kind === 'program') return 14
    if (n.kind === 'metric') return 12
    return 11
  }

  return (
    <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="xMidYMid meet">
      <defs>
        <filter id="glow">
          <feGaussianBlur stdDeviation="3" result="b" />
          <feMerge>
            <feMergeNode in="b" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>

      {BRAIN.edges.map(([a, b], i) => {
        const A = positions[a], B = positions[b]
        if (!A || !B) return null
        const active = hasActive && activeIds.has(a) && activeIds.has(b)
        const dimmed = hasActive && !active
        return (
          <line
            key={i}
            className={`edge ${active ? 'active' : ''} ${dimmed ? 'dimmed' : ''}`}
            x1={A.x} y1={A.y} x2={B.x} y2={B.y}
          />
        )
      })}

      {BRAIN.nodes.map((n) => {
        const p = positions[n.id]
        const active = hasActive && activeIds.has(n.id)
        const dimmed = hasActive && !active
        const r = sizeFor(n)
        return (
          <g
            key={n.id}
            className={`node-g ${active ? 'active' : ''} ${dimmed ? 'dimmed' : ''}`}
            transform={`translate(${p.x}, ${p.y})`}
            onMouseEnter={() => onHover && onHover(n.id)}
            onMouseLeave={() => onHover && onHover(null)}
          >
            <circle
              className="node-circle"
              r={r}
              style={active ? { fill: kindColor[n.kind], stroke: kindColor[n.kind] } : { stroke: kindColor[n.kind] }}
            />
            <text className="node-label" textAnchor="middle" y={r + 14}>
              {n.label}
            </text>
          </g>
        )
      })}
    </svg>
  )
}

export default function AskMyBrain() {
  const [messages, setMessages] = useState([])
  const [input, setInput] = useState('')
  const [thinking, setThinking] = useState(false)
  const [hoveredSrc, setHoveredSrc] = useState(null)
  const scrollRef = useRef(null)

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [messages, thinking])

  const activeIds = useMemo(() => {
    if (hoveredSrc) {
      const src = messages.flatMap(m => m.sources || []).find(s => s.id === hoveredSrc)
      if (src) return activeNodesForSources([src])
    }
    const lastBrain = [...messages].reverse().find(m => m.role === 'brain' && m.sources)
    if (lastBrain) return activeNodesForSources(lastBrain.sources)
    return new Set()
  }, [messages, hoveredSrc])

  async function ask(q) {
    const question = q.trim()
    if (!question || thinking) return

    const sources = retrieve(question, 4)
    setMessages(prev => [...prev, { role: 'user', text: question }])
    setInput('')
    setThinking(true)

    const context = sources.map((s, i) => `[${i + 1}] (${s.topic}) ${s.text}`).join('\n\n')
    const prompt = `You are "Gurinder's Brain" — answer questions about Gurinder Singh's 2026 work as if you ARE his portfolio. Use ONLY the context below. Be concise (2–4 sentences max), conversational, slightly playful. Reference specific systems/numbers when relevant. Never invent details not in the context. If the question isn't covered, say so briefly and suggest what IS in the corpus.

CONTEXT:
${context}

QUESTION: ${question}

ANSWER (concise, first-person as Gurinder, no headers, no markdown):`

    let answer = ''
    try {
      answer = await window.claude.complete(prompt)
    } catch (e) {
      // Graceful fallback: stitch the top source into a synthesized answer
      answer = sources.length
        ? `Quick take: ${sources[0].text}`
        : "Hmm — that's outside my corpus. Try asking about MAIA, Vireo, claude-cosmos, Darwin, or Mac-in-a-Mac."
    }

    setThinking(false)
    setMessages(prev => [...prev, { role: 'brain', text: answer.trim(), sources }])
  }

  return (
    <section className="bay" id="brain">
      <div className="wrap">
        <div className="eyebrow">Interactive · RAG demo on real corpus</div>
        <h2 className="section-title">
          Ask <em>my brain.</em>
        </h2>
        <p style={{ color: 'var(--text-2)', maxWidth: '62ch', fontSize: 16, lineHeight: 1.7 }}>
          A live retrieval pass over my 2026 work — same shape as the systems I build. Your question is tokenized, scored against an 18-chunk corpus, the top sources light up the knowledge graph on the right, and Claude composes the answer using only those chunks. <span style={{ color: 'var(--accent)' }}>No hallucination tax.</span>
        </p>

        <div className="brain">
          {/* chat panel */}
          <div className="brain-panel">
            <div className="brain-head">
              <div className="brain-head-l">
                <span className="dot"></span>
                <span>brain.guriboycodes</span>
              </div>
              <div className="brain-head-r">RAG · k=4 · 18 chunks</div>
            </div>

            <div className="brain-chat-body" ref={scrollRef}>
              {messages.length === 0 ? (
                <div className="brain-empty">
                  <div className="glow"></div>
                  <h4>Ask anything.</h4>
                  <p>I'll retrieve the relevant chunks from my actual 2026 corpus and answer in my own voice.</p>
                  <div className="examples">
                    {BRAIN.examples.map((ex, i) => (
                      <button key={i} onClick={() => ask(ex)}>{ex}</button>
                    ))}
                  </div>
                </div>
              ) : (
                <>
                  {messages.map((m, i) => (
                    <div key={i} className={`msg ${m.role}`}>
                      <div className="msg-role">{m.role === 'user' ? 'You' : "Gurinder's Brain"}</div>
                      <div className="msg-bubble">{m.text}</div>
                      {m.sources && m.sources.length > 0 && (
                        <div className="msg-sources">
                          {m.sources.map((s, k) => (
                            <span
                              key={k}
                              className={`src-chip ${hoveredSrc === s.id ? 'active' : ''}`}
                              onMouseEnter={() => setHoveredSrc(s.id)}
                              onMouseLeave={() => setHoveredSrc(null)}
                              title={s.text}
                            >
                              [{k + 1}] {s.topic}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                  {thinking && (
                    <div className="msg brain">
                      <div className="msg-role">Gurinder's Brain</div>
                      <div className="msg-bubble">
                        <span className="typing-dot"></span>
                        <span className="typing-dot"></span>
                        <span className="typing-dot"></span>
                      </div>
                    </div>
                  )}
                </>
              )}
            </div>

            <div className="brain-input-row">
              <input
                className="brain-input"
                placeholder="Ask about MAIA, Darwin, Vireo, hackathons, anything…"
                value={input}
                onChange={e => setInput(e.target.value)}
                onKeyDown={e => { if (e.key === 'Enter') ask(input) }}
                disabled={thinking}
              />
              <button className="brain-send" onClick={() => ask(input)} disabled={thinking || !input.trim()}>
                {thinking ? '…' : 'Ask →'}
              </button>
            </div>
          </div>

          {/* knowledge graph */}
          <div className="brain-panel brain-graph">
            <div className="brain-head">
              <div className="brain-head-l">
                <span className="dot" style={{ background: 'var(--violet)', boxShadow: '0 0 8px var(--violet)' }}></span>
                <span>knowledge_graph.v2</span>
              </div>
              <div className="brain-head-r">{BRAIN.nodes.length} nodes · {BRAIN.edges.length} edges</div>
            </div>
            <div style={{ flex: 1, position: 'relative', minHeight: 0 }}>
              <KnowledgeGraph activeIds={activeIds} onHover={setHoveredSrc} />
              <div className="graph-overlay">
                <div className="graph-legend">
                  <span><i className="lg-system"></i>system</span>
                  <span><i className="lg-program"></i>program</span>
                  <span><i className="lg-tech"></i>tech</span>
                  <span><i className="lg-metric"></i>metric</span>
                </div>
                <span>{activeIds.size ? `${activeIds.size} active` : 'idle'}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
