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

  const barVariants = {
    hidden: { scaleX: 0 },
    visible: {
      scaleX: 1,
      transition: { duration: 0.6, ease: 'easeOut' },
    },
  }

  return (
    <section id="skills" className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <motion.h2
          initial={{ opacity: 0, scale: 1.5, rotate: -4 }}
          whileInView={{ opacity: 1, scale: 1, rotate: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ type: 'spring', stiffness: 300, damping: 16 }}
          className="mb-4 text-center font-display text-3xl uppercase tracking-tight sm:text-4xl"
        >
          <span className="inline-block bg-brutal-yellow px-3 py-1 shadow-brutal">
            Technical Skills
          </span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="mb-12 text-center font-mono text-sm font-bold uppercase tracking-wide"
        >
          Mobile / AI-ML / Backend / Frontend / Tools
        </motion.p>

        {/* Category Filter */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mb-16 flex flex-wrap justify-center gap-4"
        >
          {categories.map((category) => {
            const Icon = category.icon
            return (
              <button
                key={category.name}
                onClick={() => setActiveCategory(category.name)}
                className={`brutal-btn flex items-center gap-2 px-5 py-2.5 ${
                  activeCategory === category.name
                    ? 'bg-brutal-orange'
                    : 'bg-white'
                }`}
              >
                <Icon size={18} />
                {category.name}
              </button>
            )
          })}
        </motion.div>

        {/* Skills Grid */}
        <motion.div
          key={activeCategory}
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.2 }}
          className="grid gap-x-10 gap-y-8 md:grid-cols-2 lg:grid-cols-3"
        >
          {skillsData[activeCategory].map((skill, i) => (
            <motion.div key={i} variants={itemVariants}>
              <div className="space-y-2">
                <div className="flex items-end justify-between">
                  <h3 className="text-lg font-bold uppercase">{skill.name}</h3>
                  <span className="font-mono text-sm font-bold">{skill.level}%</span>
                </div>
                <div className="h-6 border-3 border-ink bg-white">
                  <motion.div
                    variants={barVariants}
                    className="brutal-stripes h-full origin-left bg-brutal-orange"
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
