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
    <section className="overflow-hidden border-y-3 border-ink bg-ink py-4">
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
            <span className="flex-shrink-0 font-display text-lg uppercase tracking-wide text-brutal-yellow sm:text-xl">
              {item}
            </span>
            <span className="flex-shrink-0 text-brutal-orange">★</span>
          </div>
        ))}
      </motion.div>
    </section>
  )
}

export default ScrollingTicker
