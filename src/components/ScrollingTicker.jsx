import React from 'react'
import { motion } from 'framer-motion'

const ScrollingTicker = () => {
  const items = [
    'BBC Documentary Featured',
    '$60M Contract Closed',
    '500+ Interviews',
    '28+ Hackathons',
    '2x 1st Place Wins',
    'Patent Holder',
  ]

  // Duplicate items for seamless scrolling
  const displayItems = [...items, ...items]

  return (
    <section className="py-12 overflow-hidden bg-claude-primary/10 border-y border-claude-primary/20">
      <motion.div
        className="flex gap-8 whitespace-nowrap"
        animate={{ x: ['0%', '-50%'] }}
        transition={{
          duration: 20,
          repeat: Infinity,
          ease: 'linear',
        }}
      >
        {displayItems.map((item, i) => (
          <div key={i} className="flex items-center gap-8">
            <span className="text-sm sm:text-base font-semibold text-claude-primary flex-shrink-0">
              {item}
            </span>
            <div className="w-1.5 h-1.5 rounded-full bg-claude-primary flex-shrink-0" />
          </div>
        ))}
      </motion.div>
    </section>
  )
}

export default ScrollingTicker
