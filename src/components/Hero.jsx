import React from 'react'
import { motion } from 'framer-motion'
import { Github, Linkedin, Mail, Download, ArrowRight } from 'lucide-react'

const Hero = () => {
  const socialLinks = [
    { icon: Github, href: 'https://github.com/Ripnrip', label: 'GitHub' },
    { icon: Linkedin, href: 'https://www.linkedin.com/in/gurinder-singh-a30a1a48', label: 'LinkedIn' },
    { icon: Mail, href: 'mailto:gurinder@binary-bros.com', label: 'Email' },
  ]

  return (
    <section className="min-h-screen flex items-center justify-center pt-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto w-full">
        <div className="grid md:grid-cols-2 gap-8 items-center">
          {/* Left Content */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6 }}
            className="space-y-6"
          >
            <div className="space-y-2">
              <motion.h1
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.1 }}
                className="text-4xl sm:text-5xl lg:text-6xl font-bold leading-tight"
              >
                <span className="text-claude-text">Building Legendary Apps</span>
                <br />
                <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
                  at the Edge of iOS & AI
                </span>
              </motion.h1>
              <motion.p
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.2 }}
                className="text-lg text-claude-text_dim max-w-xl"
              >
                Staff iOS & AI/ML Engineer at PayPal, crafting scalable solutions with Claude's innovative approach.
              </motion.p>
            </div>

            {/* CTA Buttons */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.3 }}
              className="flex flex-wrap gap-4 pt-4"
            >
              <button className="px-6 py-3 bg-claude-primary text-claude-dark font-semibold rounded-lg hover:bg-claude-accent transition-colors flex items-center gap-2 group">
                <span>View Projects</span>
                <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
              </button>
              <button className="px-6 py-3 border border-claude-primary text-claude-primary font-semibold rounded-lg hover:bg-claude-primary/10 transition-colors flex items-center gap-2">
                <Download size={18} />
                <span>Download Resume</span>
              </button>
            </motion.div>

            {/* Social Links */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="flex gap-4 pt-4"
            >
              {socialLinks.map((link, i) => {
                const Icon = link.icon
                return (
                  <a
                    key={link.label}
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="p-3 rounded-lg bg-claude-primary/10 hover:bg-claude-primary/20 text-claude-primary transition-colors"
                    aria-label={link.label}
                  >
                    <Icon size={20} />
                  </a>
                )
              })}
            </motion.div>
          </motion.div>

          {/* Right Image */}
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="flex justify-center"
          >
            <div className="relative w-64 h-64 sm:w-80 sm:h-80 rounded-2xl overflow-hidden border-2 border-claude-primary/30">
              <img
                src="https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/images/profile/gurinder.jpg"
                alt="Gurinder Singh — GuriboyCodes"
                className="w-full h-full object-cover"
                loading="lazy"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-claude-primary/20 to-transparent"></div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

export default Hero
