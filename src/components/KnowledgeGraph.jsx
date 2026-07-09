import React, { useState } from 'react'
import { motion } from 'framer-motion'

const CX = 500
const CY = 330
const DOMAIN_RX = 330
const DOMAIN_RY = 200
const LEAF_R = 115

const domains = [
  { name: 'iOS', color: '#D97757', skills: ['Swift', 'SwiftUI', 'ARKit', 'CoreML'] },
  { name: 'AI/ML', color: '#FFC700', skills: ['RAG', 'MLX', 'Agents', 'GraphRAG'] },
  { name: 'Backend', color: '#C4B0F3', skills: ['AWS', 'Lambda', 'Node.js'] },
  { name: 'Frontend', color: '#A6E3C4', skills: ['React', 'Next.js', 'Tailwind'] },
  { name: 'Hackathons', color: '#F5B8C8', skills: ['HackZurich', 'MLH', 'BBC Drone'] },
  { name: 'Community', color: '#FFFFFF', skills: ['ERG Lead', 'Mentorship', 'CTE Board'] },
].map((domain, i, arr) => {
  const angle = (i / arr.length) * Math.PI * 2 - Math.PI / 2
  const x = CX + Math.cos(angle) * DOMAIN_RX
  const y = CY + Math.sin(angle) * DOMAIN_RY
  return {
    ...domain,
    x,
    y,
    leaves: domain.skills.map((skill, j) => {
      const spread = 0.78
      const leafAngle = angle + (j - (domain.skills.length - 1) / 2) * spread
      return {
        name: skill,
        x: x + Math.cos(leafAngle) * LEAF_R,
        y: y + Math.sin(leafAngle) * (LEAF_R * 0.72),
      }
    }),
  }
})

const Node = ({ x, y, label, fill, fontSize, pad, dim }) => {
  const width = label.length * fontSize * 0.62 + pad * 2
  const height = fontSize + pad * 1.6
  return (
    <g opacity={dim ? 0.25 : 1} style={{ transition: 'opacity 150ms' }}>
      {/* Hard offset shadow */}
      <rect x={x - width / 2 + 4} y={y - height / 2 + 4} width={width} height={height} fill="#141414" />
      <rect
        x={x - width / 2}
        y={y - height / 2}
        width={width}
        height={height}
        fill={fill}
        stroke="#141414"
        strokeWidth="3"
      />
      <text
        x={x}
        y={y}
        textAnchor="middle"
        dominantBaseline="central"
        fontSize={fontSize}
        fontWeight="bold"
        fontFamily="'Space Mono', monospace"
        fill="#141414"
        style={{ textTransform: 'uppercase' }}
      >
        {label}
      </text>
    </g>
  )
}

const KnowledgeGraph = () => {
  const [active, setActive] = useState(null)

  return (
    <section id="graph" className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <motion.h2
          initial={{ opacity: 0, scale: 1.5, rotate: -4 }}
          whileInView={{ opacity: 1, scale: 1, rotate: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ type: 'spring', stiffness: 300, damping: 16 }}
          className="mb-4 text-center font-display text-3xl uppercase tracking-tight sm:text-4xl"
        >
          <span className="inline-block bg-brutal-orange px-3 py-1 shadow-brutal">
            Knowledge Graph
          </span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="mb-8 text-center font-mono text-sm font-bold uppercase tracking-wide"
        >
          Hover / tap a domain to trace the connections
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 50, rotate: 1 }}
          whileInView={{ opacity: 1, y: 0, rotate: 0 }}
          viewport={{ once: true, amount: 0.15 }}
          transition={{ type: 'spring', stiffness: 200, damping: 20 }}
          className="brutal-card overflow-x-auto p-2 sm:p-6"
        >
          <svg viewBox="0 0 1000 660" className="mx-auto min-w-[640px] max-w-full">
            {/* Edges: center -> domains */}
            {domains.map((d) => (
              <line
                key={`edge-${d.name}`}
                x1={CX}
                y1={CY}
                x2={d.x}
                y2={d.y}
                stroke="#141414"
                strokeWidth={active === d.name ? 4 : 2}
                opacity={active && active !== d.name ? 0.15 : 1}
                style={{ transition: 'opacity 150ms' }}
              />
            ))}
            {/* Edges: domains -> leaves */}
            {domains.map((d) =>
              d.leaves.map((leaf) => (
                <line
                  key={`edge-${d.name}-${leaf.name}`}
                  x1={d.x}
                  y1={d.y}
                  x2={leaf.x}
                  y2={leaf.y}
                  stroke="#141414"
                  strokeWidth={active === d.name ? 3 : 1.5}
                  strokeDasharray={active === d.name ? 'none' : '5 4'}
                  opacity={active && active !== d.name ? 0.15 : 1}
                  style={{ transition: 'opacity 150ms' }}
                />
              ))
            )}

            {/* Leaf nodes */}
            {domains.map((d) =>
              d.leaves.map((leaf) => (
                <Node
                  key={`${d.name}-${leaf.name}`}
                  x={leaf.x}
                  y={leaf.y}
                  label={leaf.name}
                  fill="#FFFFFF"
                  fontSize={12}
                  pad={8}
                  dim={active !== null && active !== d.name}
                />
              ))
            )}

            {/* Domain nodes */}
            {domains.map((d) => (
              <g
                key={d.name}
                className="cursor-pointer"
                onMouseEnter={() => setActive(d.name)}
                onMouseLeave={() => setActive(null)}
                onClick={() => setActive(active === d.name ? null : d.name)}
              >
                <Node
                  x={d.x}
                  y={d.y}
                  label={d.name}
                  fill={d.color}
                  fontSize={16}
                  pad={12}
                  dim={active !== null && active !== d.name}
                />
              </g>
            ))}

            {/* Center node */}
            <Node x={CX} y={CY} label="Gurinder" fill="#141414" fontSize={20} pad={16} dim={false} />
            <text
              x={CX}
              y={CY}
              textAnchor="middle"
              dominantBaseline="central"
              fontSize={20}
              fontWeight="bold"
              fontFamily="'Space Mono', monospace"
              fill="#F3EFE7"
              style={{ textTransform: 'uppercase' }}
            >
              Gurinder
            </text>
          </svg>
        </motion.div>
      </div>
    </section>
  )
}

export default KnowledgeGraph
