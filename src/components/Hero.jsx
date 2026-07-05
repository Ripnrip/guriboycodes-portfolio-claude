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
    <section id="about" className="flex min-h-screen items-center justify-center px-4 pt-24 pb-16 sm:px-6 lg:px-8">
      <div className="mx-auto w-full max-w-6xl">
        <div className="grid items-center gap-12 md:grid-cols-2">
          {/* Left Content */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
            className="space-y-8"
          >
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.05 }}
              className="inline-block border-2 border-ink bg-brutal-yellow px-3 py-1 font-mono text-xs font-bold uppercase tracking-widest shadow-brutal-sm"
            >
              Staff iOS & AI/ML Engineer @ PayPal
            </motion.p>

            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="font-display text-4xl uppercase leading-none tracking-tight sm:text-5xl lg:text-6xl"
            >
              Building
              <br />
              Legendary Apps
              <br />
              <span className="mt-2 inline-block bg-brutal-orange px-2 shadow-brutal">
                at the edge of
              </span>
              <br />
              <span className="mt-2 inline-block bg-ink px-2 text-paper shadow-brutal">
                iOS & AI
              </span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="max-w-xl border-l-3 border-ink pl-4 text-lg font-medium"
            >
              Crafting scalable solutions used by 90M+ people. Shipping fast, mentoring forward, hacking everything.
            </motion.p>

            {/* CTA Buttons */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
              className="flex flex-wrap gap-4"
            >
              <a
                href="#projects"
                className="brutal-btn group flex items-center gap-2 bg-ink px-6 py-3 text-paper"
              >
                <span>View Projects</span>
                <ArrowRight size={18} className="transition-transform group-hover:translate-x-1" />
              </a>
              <a
                href="#contact"
                className="brutal-btn flex items-center gap-2 bg-white px-6 py-3"
              >
                <Download size={18} />
                <span>Resume</span>
              </a>
            </motion.div>

            {/* Social Links */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.4 }}
              className="flex gap-3"
            >
              {socialLinks.map((link) => {
                const Icon = link.icon
                return (
                  <a
                    key={link.label}
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="brutal-btn bg-brutal-lilac p-3"
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
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="flex justify-center"
          >
            <div className="relative">
              {/* Offset color block behind the photo */}
              <div className="absolute -right-4 -bottom-4 h-full w-full border-3 border-ink bg-brutal-yellow" />
              <div className="relative h-64 w-64 overflow-hidden border-3 border-ink bg-white sm:h-80 sm:w-80">
                <img
                  src="https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/images/profile/gurinder.jpg"
                  alt="Gurinder Singh — GuriboyCodes"
                  className="h-full w-full object-cover"
                  loading="lazy"
                />
              </div>
              {/* Sticker badge */}
              <div className="absolute -top-5 -left-6 rotate-[-6deg] border-3 border-ink bg-brutal-orange px-3 py-1.5 font-display text-sm uppercase shadow-brutal">
                28+ Hackathons
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

export default Hero
