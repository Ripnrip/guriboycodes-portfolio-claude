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
    { label: 'Hackathons', number: 28, suffix: '+', icon: Code, bg: 'bg-brutal-orange' },
    { label: 'Countries', number: 6, suffix: '+', icon: Globe, bg: 'bg-brutal-yellow' },
    { label: '1st Place Wins', number: 2, suffix: '', icon: Trophy, bg: 'bg-brutal-lilac' },
    { label: 'Years Active', number: 9, suffix: '+', icon: Zap, bg: 'bg-brutal-mint' },
  ]

  const getAwardStyle = (award) => {
    if (award === '1st Place') return 'bg-brutal-yellow'
    if (award === 'Finalist') return 'bg-brutal-orange'
    if (award === 'Open Source') return 'bg-brutal-mint'
    return 'bg-white'
  }

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: { staggerChildren: 0.08, delayChildren: 0.1 },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
  }

  return (
    <section id="hackathons" className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 text-center"
        >
          <h2 className="mb-6 font-display text-3xl uppercase tracking-tight sm:text-4xl">
            <span className="inline-block bg-brutal-yellow px-3 py-1 shadow-brutal">
              Hackathon Journey
            </span>
          </h2>
          <p className="mx-auto max-w-2xl font-medium">
            28+ hackathons across the globe as participant, mentor, and judge.
            From NYC to Barcelona, London to Zurich — building innovative solutions and inspiring communities.
          </p>
        </motion.div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mb-16 grid grid-cols-2 gap-4 sm:grid-cols-4"
        >
          {stats.map((stat, i) => {
            const Icon = stat.icon
            return (
              <div
                key={i}
                className={`brutal-card brutal-card-hover ${stat.bg} p-4 text-center`}
              >
                <Icon size={20} className="mx-auto mb-2" />
                <div className="mb-1 font-display text-3xl">
                  <CountUp end={stat.number} duration={2} />
                  <span>{stat.suffix}</span>
                </div>
                <p className="font-mono text-xs font-bold uppercase sm:text-sm">{stat.label}</p>
              </div>
            )
          })}
        </motion.div>

        {/* Featured Hackathons */}
        <motion.h3
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="mb-8 text-center font-display text-xl uppercase"
        >
          Featured Achievements
        </motion.h3>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="mb-16 grid gap-8 md:grid-cols-2"
        >
          {featured.map((hackathon) => (
            <motion.div
              key={hackathon.id}
              variants={itemVariants}
              onClick={() => setSelectedHackathon(hackathon)}
              className="brutal-card brutal-card-hover group cursor-pointer overflow-hidden"
            >
              {/* Image */}
              {hackathon.image && (
                <div className="relative h-48 overflow-hidden border-b-3 border-ink">
                  <img
                    src={hackathon.image}
                    alt={hackathon.name}
                    className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
                    loading="lazy"
                  />
                  <div className={`absolute top-3 right-3 border-2 border-ink px-2 py-1 font-mono text-xs font-bold uppercase shadow-brutal-sm ${getAwardStyle(hackathon.award)}`}>
                    {hackathon.award === '1st Place' ? '🥇 1st Place' : `🏆 ${hackathon.award}`}
                  </div>
                  <div className="absolute bottom-3 left-3 border-2 border-ink bg-white px-1.5 py-0.5 text-xl shadow-brutal-sm">
                    {hackathon.flag}
                  </div>
                </div>
              )}

              {/* Content */}
              <div className="p-5">
                <div className="mb-2 flex items-center gap-4 font-mono text-xs font-bold uppercase">
                  <span className="flex items-center gap-1">
                    <MapPin size={12} />
                    {hackathon.location}
                  </span>
                  <span className="flex items-center gap-1">
                    <Calendar size={12} />
                    {hackathon.year}
                  </span>
                </div>

                <h3 className="mb-1 font-display text-lg uppercase">
                  {hackathon.name} {hackathon.year}
                </h3>
                <p className="mb-2 text-sm font-bold">{hackathon.project}</p>
                <p className="mb-4 text-xs font-medium leading-relaxed">{hackathon.description}</p>

                <div className="flex items-center justify-between">
                  <div className="flex flex-wrap gap-1.5">
                    {hackathon.technologies.slice(0, 3).map((tech, i) => (
                      <span key={i} className="brutal-chip text-[10px]">
                        {tech}
                      </span>
                    ))}
                  </div>
                  {hackathon.participants && (
                    <span className="flex items-center gap-1 font-mono text-[10px] font-bold">
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
          className="mb-8 text-center font-display text-xl uppercase"
        >
          Complete Journey
        </motion.h3>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
        >
          {all.map((hackathon) => (
            <motion.div
              key={`all-${hackathon.id}`}
              variants={itemVariants}
              onClick={() => setSelectedHackathon(hackathon)}
              className={`brutal-card brutal-card-hover cursor-pointer p-4 ${
                hackathon.featured ? 'bg-white' : 'bg-paper'
              }`}
            >
              <div className="mb-2 flex items-center justify-between">
                <span className="text-xl">{hackathon.flag}</span>
                <span className={`border-2 border-ink px-2 py-0.5 font-mono text-[10px] font-bold uppercase ${getAwardStyle(hackathon.award)}`}>
                  {hackathon.award}
                </span>
              </div>
              <h4 className="mb-0.5 text-sm font-bold uppercase">{hackathon.name}</h4>
              <p className="mb-1 font-mono text-xs">{hackathon.location} · {hackathon.year}</p>
              <p className="text-xs font-bold">{hackathon.project}</p>
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
              className="fixed inset-0 z-50 flex items-center justify-center bg-ink/80 p-4"
            >
              <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.9, opacity: 0 }}
                onClick={(e) => e.stopPropagation()}
                className="relative max-h-[80vh] w-full max-w-lg overflow-y-auto border-3 border-ink bg-paper shadow-brutal-xl"
              >
                {/* Close */}
                <button
                  onClick={() => setSelectedHackathon(null)}
                  className="brutal-btn absolute top-3 right-3 z-10 flex h-9 w-9 items-center justify-center bg-brutal-orange"
                >
                  <X size={16} />
                </button>

                {/* Image */}
                {selectedHackathon.image && (
                  <div className="h-48 border-b-3 border-ink">
                    <img
                      src={selectedHackathon.image}
                      alt={selectedHackathon.name}
                      className="h-full w-full object-cover"
                    />
                  </div>
                )}

                {/* Content */}
                <div className="space-y-4 p-6">
                  <div className="flex items-center gap-3">
                    <span className="border-2 border-ink bg-white px-1.5 py-0.5 text-3xl shadow-brutal-sm">{selectedHackathon.flag}</span>
                    <div>
                      <h3 className="font-display text-xl uppercase">{selectedHackathon.name} {selectedHackathon.year}</h3>
                      <p className="flex items-center gap-2 font-mono text-sm font-bold">
                        <MapPin size={14} /> {selectedHackathon.location}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <span className={`border-2 border-ink px-3 py-1 font-mono text-sm font-bold uppercase ${getAwardStyle(selectedHackathon.award)}`}>
                      {selectedHackathon.award}
                    </span>
                    {selectedHackathon.participants && (
                      <span className="flex items-center gap-1 font-mono text-sm font-bold">
                        <Users size={14} /> {selectedHackathon.participants} participants
                      </span>
                    )}
                  </div>

                  <div>
                    <h4 className="mb-1 font-bold uppercase">{selectedHackathon.project}</h4>
                    <p className="text-sm font-medium leading-relaxed">{selectedHackathon.description}</p>
                  </div>

                  <div className="flex flex-wrap gap-2">
                    {selectedHackathon.technologies.map((tech, i) => (
                      <span key={i} className="brutal-chip">
                        {tech}
                      </span>
                    ))}
                  </div>

                  {selectedHackathon.media && (
                    <p className="flex items-center gap-2 font-mono text-xs font-bold uppercase">
                      <Tv size={14} />
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
