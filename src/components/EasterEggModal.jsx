import React from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X } from 'lucide-react'

const EasterEggModal = ({ isOpen, onClose }) => {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="fixed inset-0 bg-black/80 backdrop-blur-md z-[100] flex items-center justify-center p-4"
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
            onClick={(e) => e.stopPropagation()}
            className="relative w-full max-w-4xl bg-claude-dark rounded-lg overflow-hidden"
          >
            {/* Close Button */}
            <motion.button
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
              onClick={onClose}
              className="absolute top-4 right-4 z-10 w-10 h-10 rounded-full bg-claude-primary flex items-center justify-center hover:bg-claude-primary/90 transition-colors"
            >
              <X size={24} className="text-claude-dark" />
            </motion.button>

            {/* Fun message */}
            <div className="p-6 text-center">
              <motion.h2
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="text-2xl font-bold text-claude-primary mb-2"
              >
                You Found the Easter Egg! 🥚
              </motion.h2>
              <motion.p
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.3 }}
                className="text-claude-text_dim mb-6"
              >
                Here's a glimpse into working with me...
              </motion.p>
            </div>

            {/* Video Player */}
            <div className="aspect-video bg-black">
              <video
                src="https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/videos/working-with-me.mp4"
                controls
                autoPlay
                className="w-full h-full"
              >
                Your browser does not support the video tag.
              </video>
            </div>

            {/* Footer */}
            <div className="p-6 bg-gradient-to-r from-claude-card to-claude-card/50 text-center">
              <p className="text-sm text-claude-text_dim">
                You can trigger this again with the Konami Code (↑ ↑ ↓ ↓ ← → ← → B A) or by clicking the profile name 5 times!
              </p>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

export default EasterEggModal
