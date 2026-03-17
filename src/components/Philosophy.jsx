import React from 'react'
import { motion } from 'framer-motion'
import { Zap, Lightbulb, Users } from 'lucide-react'

const Philosophy = () => {
  const pillars = [
    {
      icon: Zap,
      title: 'Scale & Impact',
      description: 'Building systems that serve millions of users with elegance and efficiency. Every line of code matters.'
    },
    {
      icon: Lightbulb,
      title: 'Innovation',
      description: 'Pushing boundaries with AI/ML, exploring new paradigms in iOS development and emerging technologies.'
    },
    {
      icon: Users,
      title: 'Leadership',
      description: 'Mentoring teams, sharing knowledge, and elevating the next generation of engineers.'
    }
  ]

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2,
        delayChildren: 0.1,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6 },
    },
  }

  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-6xl mx-auto">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-3xl sm:text-4xl font-bold mb-12 text-center"
        >
          <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
            Engineering Philosophy
          </span>
        </motion.h2>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="grid md:grid-cols-3 gap-8"
        >
          {pillars.map((pillar, i) => {
            const Icon = pillar.icon
            return (
              <motion.div
                key={i}
                variants={itemVariants}
                className="p-8 rounded-lg bg-claude-card border border-claude-primary/20 hover:border-claude-primary/50 hover:bg-claude-card/[0.9] transition-all duration-300 group"
              >
                <div className="mb-6 inline-flex p-4 rounded-lg bg-claude-primary/20 group-hover:bg-claude-primary/30 transition-colors">
                  <Icon size={32} className="text-claude-primary" />
                </div>
                <h3 className="text-xl font-bold text-claude-text mb-4 group-hover:text-claude-primary transition-colors">
                  {pillar.title}
                </h3>
                <p className="text-claude-text_dim leading-relaxed">
                  {pillar.description}
                </p>
              </motion.div>
            )
          })}
        </motion.div>
      </div>
    </section>
  )
}

export default Philosophy
