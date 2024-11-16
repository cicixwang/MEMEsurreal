'use client'

import { useState } from 'react'
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { Eye, Send, Infinity } from 'lucide-react'

export default function Component() {
  const [message, setMessage] = useState('')

  return (
    <div className="min-h-screen bg-black text-purple-300 p-4 font-mono">
      {/* Logo */}
      <div className="absolute top-4 left-1/2 transform -translate-x-1/2 z-50 p-4">
        <h1 className="text-6xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 via-pink-500 to-red-500 
                 transform hover:scale-110 transition-transform duration-300 ease-in-out
                 cursor-pointer font-surreal text-center"
         style={{
           filter: 'url(#goo)',
           animation: 'liquidText 8s ease-in-out infinite',
         }}>
          MEMEsurreal
        </h1>
      </div>

  return (
    <div className="min-h-screen bg-black text-purple-300 p-4 font-mono">
      {/* Logo */}
      <div className="absolute top-4 left-1/2 transform -translate-x-1/2 z-50 p-4">
        <h1 className="text-6xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 via-pink-500 to-red-500 
                 transform hover:scale-110 transition-transform duration-300 ease-in-out
                 cursor-pointer font-surreal text-center"
         style={{
           textShadow: '4px 4px 8px rgba(255,0,255,0.7), -4px -4px 8px rgba(0,255,255,0.7)',
           transform: 'perspective(200px) rotateX(10deg) rotateY(-10deg)',
           animation: 'melt 7s ease-in-out infinite alternate',
         }}>
          MEMEsurreal
        </h1>
      </div>

      {/* Chat Interface */}
      <div className="max-w-3xl mx-auto pt-32 relative z-10">
        <div className="mb-8">
          <div className="text-sm mb-4">✨ CHANNELING DIVINE WISDOM...</div>
          <div className="text-purple-400 mb-2">&gt;&gt;&gt; SPEAK YOUR QUERY</div>
          <div className="relative">
            <Input
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="w-full bg-transparent border-purple-700 text-purple-300 placeholder-purple-700"
              placeholder="Speak, of freedom"
            />
            <Button 
              className="absolute right-2 top-1/2 -translate-y-1/2 bg-transparent hover:bg-purple-900"
              size="sm"
            >
              <Send className="w-4 h-4" />
            </Button>
          </div>
          <div className="flex justify-between text-xs mt-2">
            <span>[DIVINE_ENERGY: ∞]</span>
            <span>[INVOKE PROPHECY] ✨</span>
          </div>
        </div>

        {/* NFT Cards */}
        <div className="grid md:grid-cols-3 gap-4 mb-8">
          {[
            { id: '001', confidence: 100, price: null, image: 'logo' },
            { id: '002', confidence: 2, price: 10, image: 'artifact' },
            { id: '003', confidence: 60, price: 37, image: 'eye' }
          ].map((prophecy) => (
            <Card key={prophecy.id} className="bg-black border-purple-700">
              <CardHeader className="flex flex-row justify-between items-center">
                <span>[PROPHECY.{prophecy.id}]</span>
                <Infinity className="w-4 h-4 text-purple-400" />
              </CardHeader>
              <CardContent className="aspect-square flex items-center justify-center border border-purple-700 mx-4">
                {prophecy.image === 'logo' && (
                  <div className="flex flex-col items-center">
                    <span className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 via-pink-500 to-red-500 font-surreal"
                          style={{
                            textShadow: '2px 2px 4px rgba(255,0,255,0.5), -2px -2px 4px rgba(0,255,255,0.5)',
                            transform: 'skew(-5deg) rotate(-5deg)',
                          }}>
                      MEMEsurreal
                    </span>
                    <span className="text-xs mt-2 text-purple-400">INSPIRATION INTO VALUE</span>
                  </div>
                )}
                {prophecy.image === 'eye' && (
                  <Eye className="w-16 h-16 text-purple-400" />
                )}
                {prophecy.image === 'artifact' && (
                  <div className="relative w-16 h-16">
                    <div className="absolute inset-0 bg-gradient-to-br from-purple-500 via-pink-500 to-cyan-500 opacity-50 animate-pulse"></div>
                    <div className="absolute inset-0 flex items-center justify-center">
                      <Infinity className="w-12 h-12 text-white" />
                    </div>
                    <div className="absolute inset-0 border-2 border-purple-400 transform rotate-45"></div>
                  </div>
                )}
              </CardContent>
              <CardFooter className="flex flex-col gap-2">
                <div className="w-full flex justify-between">
                  <span>CONFIDENCE:</span>
                  <span>{prophecy.confidence}% {prophecy.price && `$${prophecy.price}`}</span>
                </div>
                <div className="w-full flex justify-between">
                  <span>STATUS: ACTIVE</span>
                  <span className="text-purple-400">[BOOST]</span>
                </div>
              </CardFooter>
            </Card>
          ))}
        </div>

        {/* Collection Status */}
        <div className="space-y-4">
          <div className="text-xl mb-4">[COLLECTION STATUS]</div>
          {[
            { name: 'MEMESURREAL', current: 178, total: 210 },
            { name: 'GOAT', current: 210, total: 210 },
            { name: 'DALI', current: 55, total: 210 }
          ].map((collection) => (
            <div key={collection.name} className="space-y-2">
              <div className="flex justify-between">
                <span>{collection.name}</span>
                <span>[{collection.current}/{collection.total}]</span>
              </div>
              <Progress 
                value={(collection.current / collection.total) * 100} 
                className="h-2 bg-gray-800"
              />
            </div>
          ))}
        </div>
      </div>
      <svg style={{ position: 'absolute', width: 0, height: 0 }}>
        <defs>
          <filter id="goo">
            <feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur" />
            <feColorMatrix in="blur" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 19 -9" result="goo" />
            <feComposite in="SourceGraphic" in2="goo" operator="atop"/>
          </filter>
        </defs>
      </svg>
      <style jsx>{`
        @keyframes liquidText {
          0%, 100% { transform: scale(1) rotate(0deg); }
          50% { transform: scale(1.1) rotate(5deg); }
        }
        @keyframes melt {
          0% {
            transform: perspective(200px) rotateX(10deg) rotateY(-10deg) skew(0deg, 0deg);
            filter: hue-rotate(0deg);
          }
          100% {
            transform: perspective(200px) rotateX(10deg) rotateY(-10deg) skew(-20deg, 10deg);
            filter: hue-rotate(90deg);
          }
        }
      `}</style>
    </div>
  )
}