import React from 'react'
import { motion } from 'framer-motion'
import { Users, Briefcase, Heart, Award, BookOpen, Trophy } from 'lucide-react'
import CountUp from '../utils/CountUp'

const Leadership = () => {
  const leadershipStats = [
    {
      icon: Trophy,
      number: 20,
      label: 'Engineers Mentored',
      suffix: '+',
    },
    {
      icon: Users,
      number: 150,
      label: 'ERG Members',
      suffix: '+',
    },
    {
      icon: BookOpen,
      number: 500,
      label: 'Students Reached',
      suffix: '+',
    },
    {
      icon: Award,
      number: 10,
      label: 'Years Experience',
      suffix: '+',
    },
    {
      icon: Heart,
      number: 25,
      label: 'Community Events',
      suffix: '+',
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
        staggerChildren: 0.15,
        delayChildren: 0.2,
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

  const statVariants = {
    hidden: { opacity: 0, scale: 0.8 },
    visible: {
      opacity: 1,
      scale: 1,
      transition: { duration: 0.6 },
    },
  }

  return (
    <section id="leadership" className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-transparent to-claude-primary/5">
      <div className="max-w-6xl mx-auto">
        {/* Hero Stat */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
              Community & Leadership
            </span>
          </h2>
          <div className="inline-block mt-8">
            <div className="p-8 rounded-lg bg-claude-card border border-claude-primary/30 backdrop-blur-md">
              <div className="text-5xl sm:text-6xl font-bold text-claude-primary mb-3">
                <CountUp end={500} duration={2.5} />
                <span>+</span>
              </div>
              <p className="text-lg font-semibold text-claude-text">Technical Interviews Conducted</p>
            </div>
          </div>
        </motion.div>

        {/* Stats Grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid sm:grid-cols-2 lg:grid-cols-5 gap-6 mb-16"
        >
          {leadershipStats.map((stat, i) => {
            const Icon = stat.icon
            return (
              <motion.div
                key={i}
                variants={statVariants}
                className="p-6 rounded-lg bg-claude-card border border-claude-primary/20 hover:border-claude-primary/50 transition-all duration-300 text-center group hover:shadow-lg hover:shadow-claude-primary/10"
              >
                <div className="inline-flex p-3 rounded-lg bg-claude-primary/20 group-hover:bg-claude-primary/30 transition-colors mb-4">
                  <Icon size={28} className="text-claude-primary" />
                </div>
                <div className="text-3xl font-bold text-claude-primary mb-2">
                  <CountUp end={stat.number} duration={2} />
                  <span>{stat.suffix}</span>
                </div>
                <p className="text-sm text-claude-text_dim">{stat.label}</p>
              </motion.div>
            )
          })}
        </motion.div>

        {/* Leadership Initiatives */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="mb-16"
        >
          <h3 className="text-2xl font-bold text-claude-text mb-8 text-center">Leadership Initiatives</h3>
          <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            className="grid md:grid-cols-2 gap-6"
          >
            {initiatives.map((initiative, i) => {
              const Icon = initiative.icon
              return (
                <motion.div
                  key={i}
                  variants={itemVariants}
                  className="p-6 rounded-lg bg-gradient-to-br from-claude-card to-claude-card/50 border border-claude-primary/20 hover:border-claude-primary/50 hover:shadow-lg hover:shadow-claude-primary/10 transition-all duration-300"
                >
                  <div className="flex items-start gap-4">
                    <div className="p-3 rounded-lg bg-claude-primary/20 mt-1">
                      <Icon size={24} className="text-claude-primary" />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-lg font-bold text-claude-text mb-1">{initiative.title}</h4>
                      <p className="text-sm text-claude-primary font-semibold mb-3">{initiative.period}</p>
                      <p className="text-sm leading-relaxed text-claude-text_dim">{initiative.description}</p>
                    </div>
                  </div>
                </motion.div>
              )
            })}
          </motion.div>
        </motion.div>

        {/* Featured Community Project */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="p-8 rounded-lg bg-gradient-to-br from-claude-primary/20 to-claude-secondary/10 border border-claude-primary/40 text-center"
        >
          <h3 className="text-2xl font-bold text-claude-text mb-2">Featured Community Project</h3>
          <p className="text-xl font-semibold text-claude-primary mb-3">ERG Langar App</p>
          <p className="text-claude-text_dim mb-4 max-w-2xl mx-auto">
            A React Native gamified application for Sikh temple education, combining cultural heritage with modern tech. Built to make learning about Sikh traditions engaging and accessible for the community.
          </p>
          <p className="text-sm text-claude-text_dim space-x-2">
            <span className="inline-block px-3 py-1 rounded-full bg-claude-primary/20 text-claude-primary font-semibold">React Native</span>
            <span className="inline-block px-3 py-1 rounded-full bg-claude-primary/20 text-claude-primary font-semibold">Education</span>
            <span className="inline-block px-3 py-1 rounded-full bg-claude-primary/20 text-claude-primary font-semibold">Community</span>
          </p>
        </motion.div>

        {/* Quote */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.5 }}
          className="mt-16 text-center"
        >
          <p className="text-2xl font-bold text-claude-text italic">
            "Building communities through mentorship and inclusive leadership"
          </p>
        </motion.div>
      </div>
    </section>
  )
}

export default Leadership
