import React from 'react'
import { motion } from 'framer-motion'
import { Users, Heart, Award, BookOpen, Trophy } from 'lucide-react'
import CountUp from '../utils/CountUp'

const Leadership = () => {
  const leadershipStats = [
    {
      icon: Trophy,
      number: 20,
      label: 'Engineers Mentored',
      suffix: '+',
      bg: 'bg-brutal-orange',
    },
    {
      icon: Users,
      number: 150,
      label: 'ERG Members',
      suffix: '+',
      bg: 'bg-brutal-yellow',
    },
    {
      icon: BookOpen,
      number: 500,
      label: 'Students Reached',
      suffix: '+',
      bg: 'bg-brutal-lilac',
    },
    {
      icon: Award,
      number: 10,
      label: 'Years Experience',
      suffix: '+',
      bg: 'bg-brutal-mint',
    },
    {
      icon: Heart,
      number: 25,
      label: 'Community Events',
      suffix: '+',
      bg: 'bg-brutal-pink',
    },
  ]

  const initiatives = [
    {
      title: 'CTE Advisory Board',
      period: '2023-Present',
      description: 'Guiding high school technology curriculum development and industry alignment to prepare students for tech careers.',
      icon: BookOpen,
    },
    {
      title: 'Sikh Faith ERG Leadership',
      period: '2020-Present',
      description: 'Co-Lead at PayPal with 150+ members. Building inclusive community and celebrating cultural heritage.',
      icon: Users,
    },
    {
      title: 'Technical Mentorship',
      period: '2019-Present',
      description: '500+ technical interviews conducted. Mentored 20+ engineers through career transitions and skill development.',
      icon: Trophy,
    },
    {
      title: 'Community Tech Education',
      period: '2018-Present',
      description: 'Coding workshops and educational programs for underrepresented youth in technology.',
      icon: Award,
    },
  ]

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.1,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 50, rotate: 1.5 },
    visible: {
      opacity: 1,
      y: 0,
      rotate: 0,
      transition: { type: 'spring', stiffness: 220, damping: 19 },
    },
  }

  const statVariants = {
    hidden: { opacity: 0, scale: 0.6, rotate: -3 },
    visible: {
      opacity: 1,
      scale: 1,
      rotate: 0,
      transition: { type: 'spring', stiffness: 280, damping: 15 },
    },
  }

  return (
    <section id="leadership" className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        {/* Hero Stat */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ duration: 0.5 }}
          className="mb-16 text-center"
        >
          <h2 className="mb-4 font-display text-3xl uppercase tracking-tight sm:text-4xl">
            <span className="inline-block bg-brutal-orange px-3 py-1 shadow-brutal">
              Community & Leadership
            </span>
          </h2>
          <div className="mt-10 inline-block">
            <div className="brutal-card bg-brutal-yellow p-8 shadow-brutal-lg">
              <div className="mb-3 font-display text-5xl sm:text-6xl">
                <CountUp end={500} duration={2.5} />
                <span>+</span>
              </div>
              <p className="font-mono text-lg font-bold uppercase">Technical Interviews Conducted</p>
            </div>
          </div>
        </motion.div>

        {/* Stats Grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.1 }}
          className="mb-16 grid gap-6 sm:grid-cols-2 lg:grid-cols-5"
        >
          {leadershipStats.map((stat, i) => {
            const Icon = stat.icon
            return (
              <motion.div
                key={i}
                variants={statVariants}
                className={`brutal-card brutal-card-hover ${stat.bg} p-6 text-center`}
              >
                <div className="mb-4 inline-flex border-2 border-ink bg-white p-3">
                  <Icon size={26} />
                </div>
                <div className="mb-2 font-display text-3xl">
                  <CountUp end={stat.number} duration={2} />
                  <span>{stat.suffix}</span>
                </div>
                <p className="font-mono text-xs font-bold uppercase">{stat.label}</p>
              </motion.div>
            )
          })}
        </motion.div>

        {/* Leadership Initiatives */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true, amount: 0.1 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="mb-16"
        >
          <h3 className="mb-8 text-center font-display text-2xl uppercase">Leadership Initiatives</h3>
          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, amount: 0.1 }}
            className="grid gap-6 md:grid-cols-2"
          >
            {initiatives.map((initiative, i) => {
              const Icon = initiative.icon
              return (
                <motion.div
                  key={i}
                  variants={itemVariants}
                  className="brutal-card brutal-card-hover p-6"
                >
                  <div className="flex items-start gap-4">
                    <div className="mt-1 border-2 border-ink bg-brutal-yellow p-3">
                      <Icon size={24} />
                    </div>
                    <div className="flex-1">
                      <h4 className="mb-1 font-display text-lg uppercase">{initiative.title}</h4>
                      <p className="mb-3 font-mono text-sm font-bold">{initiative.period}</p>
                      <p className="text-sm font-medium leading-relaxed">{initiative.description}</p>
                    </div>
                  </div>
                </motion.div>
              )
            })}
          </motion.div>
        </motion.div>

        {/* Featured Community Project */}
        <motion.div
          initial={{ opacity: 0, y: 50, rotate: 1.5 }}
          whileInView={{ opacity: 1, y: 0, rotate: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ type: 'spring', stiffness: 220, damping: 19 }}
          className="brutal-card bg-brutal-orange p-8 text-center shadow-brutal-lg"
        >
          <h3 className="mb-2 font-display text-2xl uppercase">Featured Community Project</h3>
          <p className="mb-3 font-mono text-xl font-bold uppercase">ERG Langar App</p>
          <p className="mx-auto mb-6 max-w-2xl font-medium">
            A React Native gamified application for Sikh temple education, combining cultural heritage with modern tech. Built to make learning about Sikh traditions engaging and accessible for the community.
          </p>
          <p className="space-x-2">
            <span className="brutal-chip">React Native</span>
            <span className="brutal-chip">Education</span>
            <span className="brutal-chip">Community</span>
          </p>
        </motion.div>

        {/* Quote */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true, amount: 0.5 }}
          transition={{ duration: 0.5 }}
          className="mt-16 text-center"
        >
          <p className="font-display text-xl uppercase sm:text-2xl">
            "Building communities through mentorship and inclusive leadership"
          </p>
        </motion.div>
      </div>
    </section>
  )
}

export default Leadership
