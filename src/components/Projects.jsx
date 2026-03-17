import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ExternalLink, Github } from 'lucide-react'
import { projects, getCategories, getProjectsByCategory } from '../data/projects'

const Projects = () => {
  const [activeCategory, setActiveCategory] = useState('All')
  const categories = getCategories()
  const displayedProjects = getProjectsByCategory(activeCategory)

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
    <section id="projects" className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-3xl sm:text-4xl font-bold mb-12 text-center"
        >
          <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
            Featured Projects
          </span>
        </motion.h2>

        {/* Category Filter */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="flex flex-wrap gap-3 mb-12 justify-center"
        >
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all duration-300 ${
                activeCategory === cat
                  ? 'bg-claude-primary text-claude-dark'
                  : 'bg-claude-card border border-claude-primary/30 text-claude-text hover:border-claude-primary/60'
              }`}
            >
              {cat}
            </button>
          ))}
        </motion.div>

        {/* Projects Grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid md:grid-cols-2 lg:grid-cols-3 gap-8"
        >
          <AnimatePresence mode="wait">
            {displayedProjects.map((project) => (
              <motion.div
                key={project.id}
                variants={itemVariants}
                exit={{ opacity: 0, y: -20 }}
                className="group rounded-lg overflow-hidden bg-claude-card border border-claude-primary/20 hover:border-claude-primary/50 transition-all duration-300 flex flex-col h-full"
              >
                {/* Image */}
                <div className="relative h-48 overflow-hidden bg-claude-primary/5">
                  <img
                    src={project.image}
                    alt={project.title}
                    className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                    loading="lazy"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-claude-dark/80 to-transparent" />

                  {project.hackathon && (
                    <div className="absolute top-3 right-3 px-3 py-1 bg-claude-primary text-claude-dark text-xs font-bold rounded-full">
                      {project.hackathon}
                    </div>
                  )}
                </div>

                {/* Content */}
                <div className="p-6 flex-1 flex flex-col">
                  <div className="mb-4">
                    <span className="inline-block px-2.5 py-1 text-xs font-semibold text-claude-primary bg-claude-primary/10 rounded-full mb-3">
                      {project.category}
                    </span>
                    <h3 className="text-lg font-bold text-claude-text mb-2 group-hover:text-claude-primary transition-colors">
                      {project.title}
                    </h3>
                    <p className="text-sm text-claude-text_dim leading-relaxed">
                      {project.description}
                    </p>
                  </div>

                  {/* Tech Stack */}
                  <div className="flex flex-wrap gap-2 mb-6 mt-auto">
                    {project.technologies.map((tech, i) => (
                      <span
                        key={i}
                        className="text-xs px-2.5 py-1 rounded bg-claude-primary/10 text-claude-secondary border border-claude-primary/20"
                      >
                        {tech}
                      </span>
                    ))}
                  </div>

                  {/* Links */}
                  <div className="flex gap-3 pt-4 border-t border-claude-primary/10">
                    <a
                      href={project.links.github}
                      className="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded bg-claude-primary/10 hover:bg-claude-primary/20 text-claude-primary text-sm font-medium transition-colors"
                    >
                      <Github size={16} />
                      <span>Code</span>
                    </a>
                    <a
                      href={project.links.demo}
                      className="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded bg-claude-primary text-claude-dark text-sm font-medium hover:bg-claude-accent transition-colors"
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
