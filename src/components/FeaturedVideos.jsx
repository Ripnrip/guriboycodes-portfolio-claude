import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Play, X } from 'lucide-react'

const FeaturedVideos = () => {
  const [selectedVideo, setSelectedVideo] = useState(null)

  const videos = [
    {
      id: 1,
      title: 'Carly — AR Car Visualizer',
      event: 'HackZurich 2018',
      url: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public/videos/hackzurich-carly.mp4',
      thumbnail: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public/images/projects/carly-ar-car-ghibli.png',
    },
    {
      id: 2,
      title: 'Elate',
      event: 'HackZurich 2022',
      url: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/videos/hackzurich-2022-elate-720p.mp4',
      thumbnail: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public/images/projects/ethereal-search-ghibli.png',
    },
    {
      id: 3,
      title: 'ARon — AI Fitness Coach',
      event: 'HackZurich 2021',
      url: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/videos/hackzurich-2021-aron-fitness.mp4',
      thumbnail: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public/images/projects/aron-ai-fitness-ghibli.png',
    },
    {
      id: 4,
      title: 'BBC Drone Documentary',
      event: 'MLH Prime 2017',
      url: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/videos/mlh-2017-drone-bbc.mp4',
      thumbnail: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public/images/projects/hylios-ghibli.png',
    },
    {
      id: 5,
      title: 'HackZurich 2018',
      event: 'Winning Solution',
      url: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/videos/hackzurich-2018.mp4',
      thumbnail: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public/images/projects/flow-ghibli.png',
    },
  ]

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.15,
        delayChildren: 0.2,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6 },
    },
  }

  return (
    <section id="videos" className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-transparent via-claude-primary/5 to-transparent">
      <div className="max-w-6xl mx-auto">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-3xl sm:text-4xl font-bold mb-12 text-center"
        >
          <span className="bg-gradient-to-r from-claude-primary to-claude-secondary bg-clip-text text-transparent">
            Featured Videos
          </span>
        </motion.h2>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="grid md:grid-cols-2 lg:grid-cols-3 gap-8"
        >
          {videos.map((video) => (
            <motion.div
              key={video.id}
              variants={itemVariants}
              whileHover={{ y: -5 }}
              className="group cursor-pointer"
              onClick={() => setSelectedVideo(video)}
            >
              <div className="relative overflow-hidden rounded-lg">
                {/* Thumbnail */}
                <img
                  src={video.thumbnail}
                  alt={video.title}
                  className="w-full h-48 object-cover group-hover:scale-110 transition-transform duration-500"
                />

                {/* Overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-claude-dark via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

                {/* Play Button */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <motion.div
                    className="w-16 h-16 rounded-full bg-claude-primary flex items-center justify-center shadow-lg shadow-claude-primary/50 group-hover:shadow-claude-primary/70 transition-all duration-300"
                    whileHover={{ scale: 1.1 }}
                  >
                    <Play size={28} className="text-claude-dark fill-claude-dark" />
                  </motion.div>
                </div>
              </div>

              {/* Card Info */}
              <div className="mt-4">
                <h3 className="text-lg font-bold text-claude-text group-hover:text-claude-primary transition-colors">{video.title}</h3>
                <p className="text-sm text-claude-primary font-semibold mt-1">{video.event}</p>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>

      {/* Video Modal */}
      <AnimatePresence>
        {selectedVideo && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setSelectedVideo(null)}
            className="fixed inset-0 bg-black/80 backdrop-blur-md z-50 flex items-center justify-center p-4"
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
                onClick={() => setSelectedVideo(null)}
                className="absolute top-4 right-4 z-10 w-10 h-10 rounded-full bg-claude-primary flex items-center justify-center hover:bg-claude-primary/90 transition-colors"
              >
                <X size={24} className="text-claude-dark" />
              </motion.button>

              {/* Video Player */}
              <div className="aspect-video bg-black">
                <video
                  src={selectedVideo.url}
                  controls
                  autoPlay
                  className="w-full h-full"
                >
                  Your browser does not support the video tag.
                </video>
              </div>

              {/* Video Info */}
              <div className="p-6 bg-gradient-to-r from-claude-card to-claude-card/50">
                <h3 className="text-2xl font-bold text-claude-text mb-2">{selectedVideo.title}</h3>
                <p className="text-lg text-claude-primary font-semibold">{selectedVideo.event}</p>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  )
}

export default FeaturedVideos
