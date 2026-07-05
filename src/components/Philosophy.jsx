import React from 'react'
import { motion } from 'framer-motion'
import { Zap, Lightbulb, Users, Rocket, Heart, Share2 } from 'lucide-react'

const Philosophy = () => {
  const pillars = [
    {
      icon: Heart,
      title: 'Ship with Soul',
      bg: 'bg-brutal-pink',
      description: 'Products should delight, not just function. Every interaction matters and deserves craftsmanship.'
    },
    {
      icon: Rocket,
      title: 'Hack the System',
      bg: 'bg-brutal-yellow',
      description: '28+ hackathons taught me to think fast and build faster. Speed meets intelligence in every project.'
    },
    {
      icon: Users,
      title: 'Mentor Forward',
      bg: 'bg-brutal-mint',
      description: '500+ interviews, 20+ engineers mentored. I believe in lifting others as I climb.'
    },
    {
      icon: Share2,
      title: 'Bridge Worlds',
      bg: 'bg-brutal-lilac',
      description: 'From mobile to AI, from PayPal to hackathons. Connecting domains creates innovation.'
    },
    {
      icon: Lightbulb,
      title: 'Community First',
      bg: 'bg-brutal-orange',
      description: 'ERG leadership, advisory boards, volunteer education. Tech thrives when everyone belongs.'
    },
    {
      icon: Zap,
      title: 'Relentless Growth',
      bg: 'bg-white',
      description: 'Stay curious, keep learning, push boundaries. Excellence is a journey, not a destination.'
    }
  ]

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.12,
        delayChildren: 0.1,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.5 },
    },
  }

  return (
    <section className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-12 text-center font-display text-3xl uppercase tracking-tight sm:text-4xl"
        >
          <span className="inline-block bg-brutal-lilac px-3 py-1 shadow-brutal">
            Engineering Philosophy
          </span>
        </motion.h2>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid gap-8 md:grid-cols-2 lg:grid-cols-3"
        >
          {pillars.map((pillar, i) => {
            const Icon = pillar.icon
            return (
              <motion.div
                key={i}
                variants={itemVariants}
                className={`brutal-card brutal-card-hover ${pillar.bg} p-8`}
              >
                <div className="mb-6 inline-flex border-3 border-ink bg-white p-3 shadow-brutal-sm">
                  <Icon size={30} />
                </div>
                <h3 className="mb-4 font-display text-xl uppercase">
                  {pillar.title}
                </h3>
                <p className="font-medium leading-relaxed">
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
