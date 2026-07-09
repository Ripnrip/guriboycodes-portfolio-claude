import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ExternalLink, Github } from 'lucide-react'
import { getCategories, getProjectsByCategory } from '../data/projects'

const Projects = () => {
  const [activeCategory, setActiveCategory] = useState('All')
  const categories = getCategories()
  const displayedProjects = getProjectsByCategory(activeCategory)

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.08,
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

  return (
    <section id="projects" className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-7xl">
        <motion.h2
          initial={{ opacity: 0, scale: 1.5, rotate: -4 }}
          whileInView={{ opacity: 1, scale: 1, rotate: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ type: 'spring', stiffness: 300, damping: 16 }}
          className="mb-12 text-center font-display text-3xl uppercase tracking-tight sm:text-4xl"
        >
          <span className="inline-block bg-brutal-mint px-3 py-1 shadow-brutal">
            Featured Projects
          </span>
        </motion.h2>

        {/* Category Filter */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ duration: 0.4, delay: 0.1 }}
          className="mb-12 flex flex-wrap justify-center gap-3"
        >
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={`brutal-btn px-4 py-2 text-sm ${
                activeCategory === cat ? 'bg-brutal-orange' : 'bg-white'
              }`}
            >
              {cat}
            </button>
          ))}
        </motion.div>

        {/* Projects Grid */}
        <motion.div
          key={activeCategory}
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.1 }}
          className="grid gap-8 md:grid-cols-2 lg:grid-cols-3"
        >
          <AnimatePresence mode="wait">
            {displayedProjects.map((project) => (
              <motion.div
                key={project.id}
                variants={itemVariants}
                exit={{ opacity: 0, y: -20 }}
                className="brutal-card brutal-card-hover group flex h-full flex-col overflow-hidden"
              >
                {/* Image */}
                <div className="relative h-48 overflow-hidden border-b-3 border-ink bg-paper">
                  <img
                    src={project.image}
                    alt={project.title}
                    className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                    loading="lazy"
                  />
                  {project.hackathon && (
                    <div className="absolute top-3 right-3 border-2 border-ink bg-brutal-yellow px-2 py-1 font-mono text-xs font-bold uppercase shadow-brutal-sm">
                      {project.hackathon}
                    </div>
                  )}
                </div>

                {/* Content */}
                <div className="flex flex-1 flex-col p-6">
                  <div className="mb-4">
                    <span className="brutal-chip mb-3 bg-brutal-lilac">
                      {project.category}
                    </span>
                    <h3 className="mb-2 font-display text-lg uppercase leading-tight">
                      {project.title}
                    </h3>
                    <p className="text-sm font-medium leading-relaxed">
                      {project.description}
                    </p>
                  </div>

                  {/* Tech Stack */}
                  <div className="mt-auto mb-6 flex flex-wrap gap-2">
                    {project.technologies.map((tech, i) => (
                      <span key={i} className="brutal-chip">
                        {tech}
                      </span>
                    ))}
                  </div>

                  {/* Links */}
                  <div className="flex gap-3">
                    <a
                      href={project.links.github}
                      className="brutal-btn flex flex-1 items-center justify-center gap-2 bg-white px-3 py-2 text-sm"
                    >
                      <Github size={16} />
                      <span>Code</span>
                    </a>
                    <a
                      href={project.links.demo}
                      className="brutal-btn flex flex-1 items-center justify-center gap-2 bg-ink px-3 py-2 text-sm text-paper"
                    >
                      <ExternalLink size={16} />
                      <span>Live</span>
                    </a>
                  </div>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </motion.div>
      </div>
    </section>
  )
}

export default Projects
