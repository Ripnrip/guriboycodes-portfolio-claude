import React from 'react'
import { motion } from 'framer-motion'

const SkillsMarquee = () => {
  const skills = [
    'Swift', 'SwiftUI', 'CoreML', 'MLX', 'RAG Systems', 'AI Agents',
    'GraphRAG', 'MCP', 'ARKit', 'React', 'Next.js', 'TypeScript',
    'Python', 'AWS Lambda', 'Node.js', 'Flutter', 'ChromaDB', 'Tailwind CSS',
  ]

  // Duplicate items for seamless scrolling
  const displayItems = [...skills, ...skills]

  return (
    <section className="overflow-hidden border-y-3 border-ink bg-brutal-yellow py-4">
      {/* Scrolls opposite to the achievements ticker */}
      <motion.div
        className="flex gap-8 whitespace-nowrap"
        animate={{ x: ['-50%', '0%'] }}
        transition={{
          duration: 30,
          repeat: Infinity,
          ease: 'linear',
        }}
      >
        {displayItems.map((item, i) => (
          <div key={i} className="flex items-center gap-8">
            <span className="flex-shrink-0 font-display text-lg uppercase tracking-wide sm:text-xl">
              {item}
            </span>
            <span className="flex-shrink-0">◆</span>
          </div>
        ))}
      </motion.div>
    </section>
  )
}

export default SkillsMarquee
