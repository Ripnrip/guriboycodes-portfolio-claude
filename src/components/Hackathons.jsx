import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { Play, X } from 'lucide-react'
import { hackathons } from '../data/hackathons'
import CountUp from '../utils/CountUp'

const Hackathons = () => {
  const [selectedVideo, setSelectedVideo] = useState(null)

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
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6 },
    },
  }

  const stats = [
    { label: 'Hackathons', number: 28, suffix: '+' },
    { label: 'Countries', number: 6, suffix: '+' },
    { label: '1st Place Wins', number: 3, suffix: '+' },
    { label: 'Years Active', number: 9, suffix: '+' },
  ]

  return (
    <section id="hackathons" className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-6xl mx-auto">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-3xl sm:text-4xl font-bold mb-4 text-center"
        >
          <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
            Hackathon Victories
          </span>
        </motion.h2>

        {/* Stats Ticker */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          viewport={{ once: true }}
          className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-16"
        >
          {stats.map((stat, i) => (
            <div
              key={i}
              className="p-4 rounded-lg bg-claude-card border border-claude-primary/20 text-center hover:border-claude-primary/50 transition-colors"
            >
              <div className="text-3xl font-bold text-claude-primary mb-1">
                <CountUp end={stat.number} duration={2} />
                <span>{stat.suffix}</span>
              </div>
              <p className="text-xs sm:text-sm text-claude-text_dim">{stat.label}</p>
            </div>
          ))}
        </motion.div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="grid md:grid-cols-2 gap-8"
        >
          {hackathons.map((hackathon) => (
            <motion.div
              key={hackathon.id}
              variants={itemVariants}
              className="group rounded-lg overflow-hidden bg-claude-card border border-claude-primary/20 hover:border-claude-primary/50 transition-all duration-300 flex flex-col"
            >
              {/* Image Container */}
              <div className="relative h-56 overflow-hidden bg-claude-primary/5">
                <img
                  src={hackathon.image}
                  alt={hackathon.name}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                  loading="lazy"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-claude-dark/80 to-transparent" />

                {/* Award Badge */}
                <div className="absolute top-4 right-4 px-4 py-1.5 bg-claude-primary text-claude-dark text-xs font-bold rounded-full">
                  {hackathon.award}
                </div>

                {/* Play Button for Videos */}
                {hackathon.videoUrl && (
                  <button
                    onClick={() => setSelectedVideo(hackathon)}
                    className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-black/40"
                  >
                    <div className="w-16 h-16 rounded-full bg-claude-primary flex items-center justify-center hover:bg-claude-accent transition-colors">
                      <Play size={28} className="text-claude-dark fill-claude-dark ml-1" />
                    </div>
                  </button>
                )}
              </div>

              {/* Content */}
              <div className="p-6 flex-1 flex flex-col">
                <div className="mb-4">
                  <p className="text-xs text-claude-text_dim mb-2">{hackathon.year}</p>
                  <h3 className="text-xl font-bold text-claude-primary mb-2">
                    {hackathon.name}
                  </h3>
                  <p className="text-lg font-semibold text-claude-text mb-2">
                    {hackathon.project}
                  </p>
                  <p className="text-sm text-claude-text_dim leading-relaxed">
                    {hackathon.description}
                  </p>
                </div>

                {/* Tech Stack */}
                <div className="flex flex-wrap gap-2 mt-auto pt-4">
                  {hackathon.technologies.map((tech, i) => (
                    <span
                      key={i}
                      className="text-xs px-2.5 py-1 rounded bg-claude-primary/10 text-claude-secondary border border-claude-primary/20"
                    >
                      {tech}
                    </span>
                  ))}
                </div>

                {/* Video CTA */}
                {hackathon.videoUrl && (
                  <button
                    onClick={() => setSelectedVideo(hackathon)}
                    className="mt-6 w-full px-4 py-2 rounded bg-claude-primary text-claude-dark font-semibold hover:bg-claude-accent transition-colors flex items-center justify-center gap-2"
                  >
                    <Play size={16} className="fill-current" />
                    <span>Watch Video</span>
                  </button>
                )}
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* Video Modal */}
        {selectedVideo && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setSelectedVideo(null)}
            className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4"
          >
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-4xl rounded-lg overflow-hidden"
            >
              <div className="relative bg-claude-dark">
                <button
                  onClick={() => setSelectedVideo(null)}
                  className="absolute top-4 right-4 p-2 rounded-full bg-claude-primary text-claude-dark hover:bg-claude-accent transition-colors z-10"
                >
                  <X size={24} />
                </button>
                <video
                  src={selectedVideo.videoUrl}
                  controls
                  autoPlay
                  className="w-full aspect-video"
                />
              </div>
            </motion.div>
          </motion.div>
        )}
      </div>
    </section>
  )
}

export default Hackathons
