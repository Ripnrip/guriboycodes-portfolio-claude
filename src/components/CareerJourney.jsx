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
      achievements: [
        'Wealth Management iOS app',
        'Financial data visualization',
        'Secure authentication'
      ],
      technologies: ['iOS', 'Swift', 'FinTech', 'Security'],
    },
  ]

  return (
    <section id="experience" className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-3xl sm:text-4xl font-bold mb-12 text-center"
        >
          <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
            Career Journey
          </span>
        </motion.h2>

        <div className="space-y-4">
          {positions.map((position, i) => (
            <motion.div
              key={position.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: i * 0.1 }}
            >
              <button
                onClick={() => setExpandedId(expandedId === position.id ? -1 : position.id)}
                className="w-full text-left p-6 rounded-lg bg-claude-card border border-claude-primary/20 hover:border-claude-primary/50 transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <h3 className="text-xl font-bold text-claude-primary mb-1">
                      {position.company}
                    </h3>
                    <p className="text-claude-text mb-2">{position.role}</p>
                    <p className="text-sm text-claude-text_dim">{position.period}</p>
                  </div>
                  <motion.div
                    animate={{ rotate: expandedId === position.id ? 180 : 0 }}
                    transition={{ duration: 0.3 }}
                  >
                    <ChevronDown className="text-claude-primary" size={24} />
                  </motion.div>
                </div>
              </button>

              <AnimatePresence>
                {expandedId === position.id && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.3 }}
                    className="overflow-hidden"
                  >
                    <div className="p-6 bg-claude-card/50 border border-t-0 border-claude-primary/20 rounded-b-lg space-y-4">
                      <div>
                        <h4 className="text-sm font-semibold text-claude-primary mb-3">
                          Key Achievements
                        </h4>
                        <ul className="space-y-2">
                          {position.achievements.map((achievement, j) => (
                            <li key={j} className="flex items-start gap-3 text-sm text-claude-text_dim">
                              <span className="w-2 h-2 rounded-full bg-claude-primary mt-1.5 flex-shrink-0" />
                              <span>{achievement}</span>
                            </li>
                          ))}
                        </ul>
                      </div>
                      <div>
                        <h4 className="text-sm font-semibold text-claude-primary mb-2">
                          Technologies
                        </h4>
                        <div className="flex flex-wrap gap-2">
                          {position.technologies.map((tech, j) => (
                            <span
                              key={j}
                              className="px-3 py-1 rounded-full bg-claude-primary/20 text-claude-primary text-xs font-medium"
                            >
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
