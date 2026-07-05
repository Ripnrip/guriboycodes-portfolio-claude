import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDown } from 'lucide-react'

const CareerJourney = () => {
  const [expandedId, setExpandedId] = useState(0)

  const positions = [
    {
      id: 0,
      company: 'PayPal',
      role: 'Staff Software Engineer',
      period: '2020 - Present',
      accent: 'bg-brutal-orange',
      achievements: [
        'Agent0 — Deployed autonomous AI agent framework to Venmo & PayPal engineering teams',
        'Project Mercury — AI-Powered Agentic E-Commerce (GraphRAG/MCP), prototype built in 72 hrs, presented to SVP of AI',
        '$400M Amex partnership',
        '$60M CVS contract',
        'QRC Widget Patent (66% friction reduction)',
        'Venmo × Amazon integration',
        'Dynamic Island/Live Activities',
        '90M+ users impacted'
      ],
      technologies: ['iOS', 'SwiftUI', 'Python', 'GraphRAG', 'MCP', 'AI Agents', 'SDXL LoRA'],
    },
    {
      id: 1,
      company: 'Google Stadia / HCL',
      role: 'Software Engineer',
      period: '2019 - 2020',
      accent: 'bg-brutal-yellow',
      achievements: [
        'Flutter/iOS development',
        'Core Bluetooth for Stadia controller',
        'Real-time cloud gaming features'
      ],
      technologies: ['Flutter', 'iOS', 'Bluetooth', 'Swift'],
    },
    {
      id: 2,
      company: 'Morgan Stanley',
      role: 'iOS Developer',
      period: '2018 - 2019',
      accent: 'bg-brutal-lilac',
      achievements: [
        'Wealth Management iOS app',
        'Financial data visualization',
        'Secure authentication'
      ],
      technologies: ['iOS', 'Swift', 'FinTech', 'Security'],
    },
  ]

  return (
    <section id="experience" className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-4xl">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-12 text-center font-display text-3xl uppercase tracking-tight sm:text-4xl"
        >
          <span className="inline-block bg-brutal-orange px-3 py-1 shadow-brutal">
            Career Journey
          </span>
        </motion.h2>

        <div className="space-y-6">
          {positions.map((position, i) => (
            <motion.div
              key={position.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: i * 0.1 }}
              className="brutal-card"
            >
              <button
                onClick={() => setExpandedId(expandedId === position.id ? -1 : position.id)}
                className="w-full p-6 text-left"
              >
                <div className="flex items-center justify-between gap-4">
                  <div className="flex-1">
                    <div className="mb-2 flex flex-wrap items-center gap-3">
                      <h3 className="font-display text-xl uppercase">
                        {position.company}
                      </h3>
                      <span className={`border-2 border-ink px-2 py-0.5 font-mono text-xs font-bold uppercase ${position.accent}`}>
                        {position.period}
                      </span>
                    </div>
                    <p className="font-bold">{position.role}</p>
                  </div>
                  <motion.div
                    animate={{ rotate: expandedId === position.id ? 180 : 0 }}
                    transition={{ duration: 0.2 }}
                    className="flex h-9 w-9 flex-shrink-0 items-center justify-center border-2 border-ink bg-white"
                  >
                    <ChevronDown size={22} />
                  </motion.div>
                </div>
              </button>

              <AnimatePresence>
                {expandedId === position.id && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.25 }}
                    className="overflow-hidden"
                  >
                    <div className="space-y-5 border-t-3 border-ink bg-paper p-6">
                      <div>
                        <h4 className="mb-3 font-mono text-xs font-bold uppercase tracking-widest">
                          Key Achievements
                        </h4>
                        <ul className="space-y-2">
                          {position.achievements.map((achievement, j) => (
                            <li key={j} className="flex items-start gap-3 text-sm font-medium">
                              <span className="mt-1.5 h-2 w-2 flex-shrink-0 bg-ink" />
                              <span>{achievement}</span>
                            </li>
                          ))}
                        </ul>
                      </div>
                      <div>
                        <h4 className="mb-2 font-mono text-xs font-bold uppercase tracking-widest">
                          Technologies
                        </h4>
                        <div className="flex flex-wrap gap-2">
                          {position.technologies.map((tech, j) => (
                            <span key={j} className="brutal-chip">
                              {tech}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default CareerJourney
