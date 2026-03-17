import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { Smartphone, Brain, Server, Palette, Wrench } from 'lucide-react'

const Skills = () => {
  const [activeCategory, setActiveCategory] = useState('Mobile')

  const skillsData = {
    Mobile: [
      { name: 'Swift', level: 95 },
      { name: 'SwiftUI', level: 90 },
      { name: 'iOS SDK', level: 95 },
      { name: 'Objective-C', level: 85 },
      { name: 'Flutter', level: 80 },
      { name: 'Dart', level: 75 },
      { name: 'React Native', level: 70 },
    ],
    'AI/ML': [
      { name: 'CoreML', level: 90 },
      { name: 'MLX', level: 85 },
      { name: 'RAG Systems', level: 88 },
      { name: 'ChromaDB', level: 80 },
      { name: 'OpenAI APIs', level: 85 },
      { name: 'Vector DBs', level: 82 },
      { name: 'Python ML', level: 75 },
    ],
    Backend: [
      { name: 'Node.js', level: 80 },
      { name: 'AWS', level: 85 },
      { name: 'Serverless', level: 82 },
      { name: 'DynamoDB', level: 78 },
      { name: 'Lambda', level: 80 },
      { name: 'API Design', level: 90 },
      { name: 'Microservices', level: 85 },
    ],
    Frontend: [
      { name: 'React', level: 88 },
      { name: 'Next.js', level: 85 },
      { name: 'TypeScript', level: 82 },
      { name: 'Tailwind CSS', level: 90 },
      { name: 'JavaScript', level: 90 },
      { name: 'HTML/CSS', level: 95 },
      { name: 'Vite', level: 80 },
    ],
    Tools: [
      { name: 'Xcode', level: 95 },
      { name: 'Git', level: 90 },
      { name: 'GitHub', level: 88 },
      { name: 'Figma', level: 75 },
      { name: 'Supabase', level: 80 },
      { name: 'Vercel', level: 85 },
      { name: 'Docker', level: 70 },
    ],
  }

  const categories = [
    { name: 'Mobile', icon: Smartphone },
    { name: 'AI/ML', icon: Brain },
    { name: 'Backend', icon: Server },
    { name: 'Frontend', icon: Palette },
    { name: 'Tools', icon: Wrench },
  ]

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

  const barVariants = {
    hidden: { scaleX: 0 },
    visible: {
      scaleX: 1,
      transition: { duration: 0.8, ease: 'easeOut' },
    },
  }

  return (
    <section id="skills" className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-transparent via-claude-primary/5 to-transparent">
      <div className="max-w-6xl mx-auto">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-3xl sm:text-4xl font-bold mb-2 text-center"
        >
          <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
            Technical Skills
          </span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-center text-claude-text_dim mb-12"
        >
          Expertise across mobile, AI/ML, backend, frontend, and development tools
        </motion.p>

        {/* Category Filter */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="flex flex-wrap justify-center gap-4 mb-16"
        >
          {categories.map((category) => {
            const Icon = category.icon
            return (
              <motion.button
                key={category.name}
                onClick={() => setActiveCategory(category.name)}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className={`flex items-center gap-2 px-6 py-3 rounded-lg font-medium transition-all duration-300 ${
                  activeCategory === category.name
                    ? 'bg-claude-primary text-claude-dark shadow-lg shadow-claude-primary/30'
                    : 'bg-claude-card border border-claude-primary/20 text-claude-text hover:border-claude-primary/50'
                }`}
              >
                <Icon size={20} />
                {category.name}
              </motion.button>
            )
          })}
        </motion.div>

        {/* Skills Grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid md:grid-cols-2 lg:grid-cols-3 gap-8"
        >
          {skillsData[activeCategory].map((skill, i) => (
            <motion.div key={i} variants={itemVariants}>
              <div className="space-y-3">
                <div className="flex justify-between items-end">
                  <h3 className="text-lg font-semibold text-claude-text">{skill.name}</h3>
                  <span className="text-sm text-claude-primary font-bold">{skill.level}%</span>
                </div>
                <div className="h-2 bg-claude-card rounded-full overflow-hidden">
                  <motion.div
                    variants={barVariants}
                    className="h-full bg-gradient-to-r from-claude-primary to-claude-secondary rounded-full origin-left"
                    style={{ width: `${skill.level}%` }}
                  />
                </div>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}

export default Skills
