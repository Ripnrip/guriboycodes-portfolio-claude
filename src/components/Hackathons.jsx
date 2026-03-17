import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { MapPin, Calendar, Users, Tv, X, Trophy, Globe, Code, Zap } from 'lucide-react'
import { hackathons } from '../data/hackathons'
import CountUp from '../utils/CountUp'

const Hackathons = () => {
  const [selectedHackathon, setSelectedHackathon] = useState(null)

  const featured = hackathons.filter(h => h.featured)
  const all = hackathons

  const stats = [
    { label: 'Hackathons', number: 28, suffix: '+', icon: Code },
    { label: 'Countries', number: 6, suffix: '+', icon: Globe },
    { label: '1st Place Wins', number: 2, suffix: '', icon: Trophy },
    { label: 'Years Active', number: 9, suffix: '+', icon: Zap },
  ]

  const getAwardStyle = (award) => {
    if (award === '1st Place') return 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30'
    if (award === 'Finalist') return 'bg-claude-primary/20 text-claude-primary border-claude-primary/30'
    if (award === 'Open Source') return 'bg-green-500/20 text-green-400 border-green-500/30'
    return 'bg-claude-text_dim/20 text-claude-text_dim border-claude-text_dim/30'
  }

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: { staggerChildren: 0.1, delayChildren: 0.2 },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
  }

  return (
    <section id="hackathons" className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-6xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-6"
        >
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
              Hackathon Journey
            </span>
          </h2>
          <p className="text-claude-text_dim max-w-2xl mx-auto">
            28+ hackathons across the globe as participant, mentor, and judge.
            From NYC to Barcelona, London to Zurich — building innovative solutions and inspiring communities.
          </p>
        </motion.div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-16"
        >
          {stats.map((stat, i) => {
            const Icon = stat.icon
            return (
              <div
                key={i}
                className="p-4 rounded-lg bg-claude-card border border-claude-primary/20 text-center hover:border-claude-primary/50 transition-colors"
              >
                <Icon size={20} className="text-claude-primary mx-auto mb-2" />
                <div className="text-3xl font-bold text-claude-primary mb-1">
                  <CountUp end={stat.number} duration={2} />
                  <span>{stat.suffix}</span>
                </div>
                <p className="text-xs sm:text-sm text-claude-text_dim">{stat.label}</p>
              </div>
            )
          })}
        </motion.div>

        {/* Featured Hackathons */}
        <motion.h3
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-xl font-bold text-center mb-8"
        >
          <span className="text-claude-primary">Featured Achievements</span>
        </motion.h3>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid md:grid-cols-2 gap-6 mb-16"
        >
          {featured.map((hackathon) => (
            <motion.div
              key={hackathon.id}
              variants={itemVariants}
              whileHover={{ y: -4 }}
              onClick={() => setSelectedHackathon(hackathon)}
              className="group cursor-pointer rounded-lg overflow-hidden bg-claude-card border border-claude-primary/20 hover:border-claude-primary/50 transition-all duration-300"
            >
              {/* Image */}
              {hackathon.image && (
                <div className="relative h-48 overflow-hidden">
                  <img
                    src={hackathon.image}
                    alt={hackathon.name}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    loading="lazy"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-claude-dark/80 via-transparent to-transparent" />
                  <div className={`absolute top-3 right-3 px-3 py-1 text-xs font-bold rounded-full border ${getAwardStyle(hackathon.award)}`}>
                    {hackathon.award === '1st Place' ? '🥇 1st Place' : `🏆 ${hackathon.award}`}
                  </div>
                  <div className="absolute bottom-3 left-3 text-2xl">{hackathon.flag}</div>
                </div>
              )}

              {/* Content */}
              <div className="p-5">
                <div className="flex items-center gap-3 text-xs text-claude-text_dim mb-2">
                  <span className="flex items-center gap-1">
                    <MapPin size={12} />
                    {hackathon.location}
                  </span>
                  <span className="flex items-center gap-1">
                    <Calendar size={12} />
                    {hackathon.year}
                  </span>
                </div>

                <h3 className="text-lg font-bold text-claude-primary mb-1">
                  {hackathon.name} {hackathon.year}
                </h3>
                <p className="text-sm font-semibold text-claude-text mb-2">{hackathon.project}</p>
                <p className="text-xs text-claude-text_dim leading-relaxed mb-4">{hackathon.description}</p>

                <div className="flex items-center justify-between">
                  <div className="flex flex-wrap gap-1.5">
                    {hackathon.technologies.slice(0, 3).map((tech, i) => (
                      <span
                        key={i}
                        className="text-[10px] px-2 py-0.5 rounded bg-claude-primary/10 text-claude-secondary border border-claude-primary/20"
                      >
                        {tech}
                      </span>
                    ))}
                  </div>
                  {hackathon.participants && (
                    <span className="flex items-center gap-1 text-[10px] text-claude-text_dim">
                      <Users size={10} />
                      {hackathon.participants}
                    </span>
                  )}
                </div>
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* Complete Journey */}
        <motion.h3
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-xl font-bold text-center mb-8"
        >
          <span className="text-claude-primary">Complete Journey</span>
        </motion.h3>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4"
        >
          {all.map((hackathon) => (
            <motion.div
              key={`all-${hackathon.id}`}
              variants={itemVariants}
              whileHover={{ y: -3 }}
              onClick={() => setSelectedHackathon(hackathon)}
              className={`cursor-pointer rounded-lg p-4 border transition-all duration-300 hover:border-claude-primary/50 ${
                hackathon.featured
                  ? 'bg-claude-card border-claude-primary/30'
                  : 'bg-claude-card/60 border-claude-primary/10'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-xl">{hackathon.flag}</span>
                <span className={`text-[10px] px-2 py-0.5 rounded-full border font-semibold ${getAwardStyle(hackathon.award)}`}>
                  {hackathon.award}
                </span>
              </div>
              <h4 className="text-sm font-bold text-claude-text mb-0.5">{hackathon.name}</h4>
              <p className="text-xs text-claude-text_dim mb-1">{hackathon.location} · {hackathon.year}</p>
              <p className="text-xs text-claude-primary font-medium">{hackathon.project}</p>
            </motion.div>
          ))}
        </motion.div>

        {/* Detail Modal */}
        <AnimatePresence>
          {selectedHackathon && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setSelectedHackathon(null)}
              className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4"
            >
              <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.9, opacity: 0 }}
                onClick={(e) => e.stopPropagation()}
                className="relative w-full max-w-lg bg-claude-card border border-claude-primary/30 rounded-lg overflow-hidden max-h-[80vh] overflow-y-auto"
              >
                {/* Close */}
                <button
                  onClick={() => setSelectedHackathon(null)}
                  className="absolute top-3 right-3 z-10 w-8 h-8 rounded-full bg-claude-dark/80 border border-claude-primary/30 flex items-center justify-center hover:bg-claude-primary/20 transition-colors"
                >
                  <X size={16} className="text-claude-text" />
                </button>

                {/* Image */}
                {selectedHackathon.image && (
                  <div className="relative h-48">
                    <img
                      src={selectedHackathon.image}
                      alt={selectedHackathon.name}
                      className="w-full h-full object-cover"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-claude-card to-transparent" />
                  </div>
                )}

                {/* Content */}
                <div className="p-6 space-y-4">
                  <div className="flex items-center gap-3">
                    <span className="text-3xl">{selectedHackathon.flag}</span>
                    <div>
                      <h3 className="text-xl font-bold text-claude-primary">{selectedHackathon.name} {selectedHackathon.year}</h3>
                      <p className="text-sm text-claude-text_dim flex items-center gap-2">
                        <MapPin size={14} /> {selectedHackathon.location}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <span className={`px-3 py-1 text-sm font-bold rounded-full border ${getAwardStyle(selectedHackathon.award)}`}>
                      {selectedHackathon.award}
                    </span>
                    {selectedHackathon.participants && (
                      <span className="flex items-center gap-1 text-sm text-claude-text_dim">
                        <Users size={14} /> {selectedHackathon.participants} participants
                      </span>
                    )}
                  </div>

                  <div>
                    <h4 className="font-semibold text-claude-text mb-1">{selectedHackathon.project}</h4>
                    <p className="text-sm text-claude-text_dim leading-relaxed">{selectedHackathon.description}</p>
                  </div>

                  <div className="flex flex-wrap gap-2">
                    {selectedHackathon.technologies.map((tech, i) => (
                      <span
                        key={i}
                        className="text-xs px-2.5 py-1 rounded bg-claude-primary/10 text-claude-secondary border border-claude-primary/20"
                      >
                        {tech}
                      </span>
                    ))}
                  </div>

                  {selectedHackathon.media && (
                    <p className="flex items-center gap-2 text-xs text-claude-text_dim">
                      <Tv size={14} className="text-claude-primary" />
                      Media: {selectedHackathon.media}
                    </p>
                  )}
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </section>
  )
}

export default Hackathons
