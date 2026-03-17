import React from 'react'
import { motion } from 'framer-motion'
import { Github, Linkedin, Mail, ExternalLink } from 'lucide-react'

const Contact = () => {
  const socialLinks = [
    { icon: Github, href: 'https://github.com/Ripnrip', label: 'GitHub' },
    { icon: Linkedin, href: 'https://www.linkedin.com/in/gurinder-singh-a30a1a48', label: 'LinkedIn' },
    { icon: Mail, href: 'mailto:gurinder@binary-bros.com', label: 'Email' },
  ]

  return (
    <section id="contact" className="py-20 px-4 sm:px-6 lg:px-8 border-t border-claude-primary/20">
      <div className="max-w-4xl mx-auto text-center">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          viewport={{ once: true }}
          className="text-3xl sm:text-4xl font-bold mb-6"
        >
          <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
            Let's Connect
          </span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 10 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          viewport={{ once: true }}
          className="text-lg text-claude-text_dim mb-12 max-w-2xl mx-auto"
        >
          Interested in collaborating on innovative projects? Get in touch and let's build something legendary together.
        </motion.p>

        {/* Social Links */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          viewport={{ once: true }}
          className="flex justify-center gap-6 mb-16"
        >
          {socialLinks.map((link) => {
            const Icon = link.icon
            return (
              <a
                key={link.label}
                href={link.href}
                target="_blank"
                rel="noopener noreferrer"
                className="p-4 rounded-lg bg-claude-card border border-claude-primary/30 hover:border-claude-primary/60 hover:bg-claude-primary/10 transition-all duration-300 group"
              >
                <Icon size={24} className="text-claude-primary group-hover:scale-110 transition-transform" />
              </a>
            )
          })}
        </motion.div>

        {/* CTA Button */}
        <motion.a
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          viewport={{ once: true }}
          href="mailto:gurinder@binary-bros.com"
          className="inline-flex items-center gap-2 px-8 py-3 bg-claude-primary text-claude-dark font-semibold rounded-lg hover:bg-claude-accent transition-colors group"
        >
          <span>Send me an email</span>
          <ExternalLink size={18} className="group-hover:translate-x-1 transition-transform" />
        </motion.a>

        {/* Footer */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          viewport={{ once: true }}
          className="mt-20 pt-12 border-t border-claude-primary/10 text-center"
        >
          <p className="text-sm text-claude-text_dim mb-4">
            Built with <span className="text-claude-primary">Claude</span> — AI-powered development
          </p>
          <p className="text-xs text-claude-text_dim/70">
            © {new Date().getFullYear()} GuriboyCodes. All rights reserved.
          </p>
          <div className="mt-6 flex items-center justify-center gap-2 text-xs text-claude-text_dim/70">
            <span>Powered by</span>
            <a
              href="https://claude.ai"
              target="_blank"
              rel="noopener noreferrer"
              className="text-claude-primary hover:text-claude-accent transition-colors"
            >
              Claude AI
            </a>
            <span>•</span>
            <a
              href="https://vitejs.dev"
              target="_blank"
              rel="noopener noreferrer"
              className="text-claude-primary hover:text-claude-accent transition-colors"
            >
              Vite
            </a>
            <span>•</span>
            <a
              href="https://tailwindcss.com"
              target="_blank"
              rel="noopener noreferrer"
              className="text-claude-primary hover:text-claude-accent transition-colors"
            >
              Tailwind CSS
            </a>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default Contact
