import React from 'react'
import { motion } from 'framer-motion'

// Shared choreography for the HyperFrames-style motion system:
// springy "stamp" entrances, staggered slams, scroll-triggered reveals.

export const VIEWPORT = { once: true, amount: 0.2 }

export const SPRING = { type: 'spring', stiffness: 260, damping: 20 }

// Big elements stamp down onto the page like a rubber stamp
export const stamp = {
  hidden: { opacity: 0, scale: 1.5, rotate: -4 },
  visible: {
    opacity: 1,
    scale: 1,
    rotate: 0,
    transition: { type: 'spring', stiffness: 300, damping: 16 },
  },
}

// Cards/blocks slam up into place with a slight settle
export const slamUp = {
  hidden: { opacity: 0, y: 50, rotate: 1.5 },
  visible: {
    opacity: 1,
    y: 0,
    rotate: 0,
    transition: { type: 'spring', stiffness: 220, damping: 19 },
  },
}

export const staggerParent = (stagger = 0.09, delay = 0.05) => ({
  hidden: {},
  visible: { transition: { staggerChildren: stagger, delayChildren: delay } },
})

// Section heading that stamps in when scrolled into view
export const SectionTitle = ({ bg, className = 'mb-4', children }) => (
  <motion.h2
    initial="hidden"
    whileInView="visible"
    viewport={VIEWPORT}
    variants={stamp}
    className={`text-center font-display text-3xl uppercase tracking-tight sm:text-4xl ${className}`}
  >
    <span className={`inline-block ${bg} px-3 py-1 shadow-brutal`}>{children}</span>
  </motion.h2>
)

// Kinetic typography: each word slides up out of a clipped box, staggered
export const KineticWords = ({ text, delay = 0, wordClassName = '' }) => (
  <motion.span
    initial="hidden"
    animate="visible"
    variants={staggerParent(0.08, delay)}
    className="inline"
    aria-label={text}
  >
    {text.split(' ').map((word, i) => (
      <span key={i} className="inline-block overflow-hidden pb-[0.08em] align-bottom" aria-hidden="true">
        <motion.span
          className={`inline-block ${wordClassName}`}
          variants={{
            hidden: { y: '110%' },
            visible: { y: '0%', transition: { type: 'spring', stiffness: 320, damping: 24 } },
          }}
        >
          {word}
        </motion.span>
        {i < text.split(' ').length - 1 && <span className="inline-block">&nbsp;</span>}
      </span>
    ))}
  </motion.span>
)
