import React from 'react'
import { motion } from 'framer-motion'
import CountUp from '../utils/CountUp'

const Stats = () => {
  const stats = [
    { label: 'Users Impacted', value: '90M', suffix: '+' },
    { label: 'Interviews', value: '500', suffix: '+' },
    { label: 'Hackathons', value: '28', suffix: '+' },
    { label: 'Years Experience', value: '8', suffix: '+' },
  ]

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.2,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6 },
    },
  }

  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-claude-dark to-claude-dark/50">
      <div className="max-w-6xl mx-auto">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="grid grid-cols-2 md:grid-cols-4 gap-8"
        >
          {stats.map((stat, i) => (
            <motion.div
              key={i}
              variants={itemVariants}
              className="text-center p-6 rounded-lg bg-claude-card border border-claude-primary/10 hover:border-claude-primary/30 transition-colors"
            >
              <div className="text-3xl sm:text-4xl font-bold text-claude-primary mb-2">
                <CountUp end={parseInt(stat.value)} />
                {stat.suffix}
              </div>
              <p className="text-sm sm:text-base text-claude-text_dim">{stat.label}</p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}

export default Stats
