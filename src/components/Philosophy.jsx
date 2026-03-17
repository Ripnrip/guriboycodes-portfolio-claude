import React from 'react'
import { motion } from 'framer-motion'
import { Zap, Lightbulb, Users, Rocket, Heart, Share2 } from 'lucide-react'

const Philosophy = () => {
  const pillars = [
    {
      icon: Heart,
      title: 'Ship with Soul',
      description: 'Products should delight, not just function. Every interaction matters and deserves craftsmanship.'
    },
    {
      icon: Rocket,
      title: 'Hack the System',
      description: '28+ hackathons taught me to think fast and build faster. Speed meets intelligence in every project.'
    },
    {
      icon: Users,
      title: 'Mentor Forward',
      description: '500+ interviews, 20+ engineers mentored. I believe in lifting others as I climb.'
    },
    {
      icon: Share2,
      title: 'Bridge Worlds',
      description: 'From mobile to AI, from PayPal to hackathons. Connecting domains creates innovation.'
    },
    {
      icon: Lightbulb,
      title: 'Community First',
      description: 'ERG leadership, advisory boards, volunteer education. Tech thrives when everyone belongs.'
    },
    {
      icon: Zap,
      title: 'Relentless Growth',
      description: 'Stay curious, keep learning, push boundaries. Excellence is a journey, not a destination.'
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
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-3xl sm:text-4xl font-bold mb-12 text-center"
        >
          <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
            Engineering Philosophy
          </span>
        </motion.h2>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid md:grid-cols-2 lg:grid-cols-3 gap-8"
        >
          {pillars.map((pillar, i) => {
            const Icon = pillar.icon
            return (
              <motion.div
                key={i}
                variants={itemVariants}
                className="p-8 rounded-lg bg-gradient-to-br from-claude-card to-claude-card/50 border border-claude-primary/20 hover:border-claude-primary/50 hover:shadow-lg hover:shadow-claude-primary/20 transition-all duration-300 group"
                whileHover={{ y: -8 }}
              >
                <motion.div
                  className="mb-6 inline-flex p-4 rounded-lg bg-claude-primary/20 group-hover:bg-claude-primary/30 transition-colors"
                  whileHover={{ rotate: 10, scale: 1.1 }}
                >
                  <Icon size={32} className="text-claude-primary" />
                </motion.div>
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
