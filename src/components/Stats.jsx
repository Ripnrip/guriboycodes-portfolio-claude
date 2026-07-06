import React from 'react'
import { motion } from 'framer-motion'
import CountUp from '../utils/CountUp'

const Stats = () => {
  const stats = [
    { label: 'Users Impacted', value: '90', suffix: 'M+', bg: 'bg-brutal-orange' },
    { label: 'Interviews', value: '500', suffix: '+', bg: 'bg-brutal-yellow' },
    { label: 'Hackathons', value: '28', suffix: '+', bg: 'bg-brutal-lilac' },
    { label: 'Years Experience', value: '8', suffix: '+', bg: 'bg-brutal-mint' },
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
      transition: { duration: 0.5 },
    },
  }

  return (
    <section className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid grid-cols-2 gap-6 md:grid-cols-4"
        >
          {stats.map((stat, i) => (
            <motion.div
              key={i}
              variants={itemVariants}
              className={`brutal-card brutal-card-hover ${stat.bg} p-6 text-center`}
            >
              <div className="mb-2 font-display text-3xl sm:text-4xl">
                <CountUp end={parseInt(stat.value)} />
                {stat.suffix}
              </div>
              <p className="font-mono text-xs font-bold uppercase tracking-wide sm:text-sm">
                {stat.label}
              </p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}

export default Stats
