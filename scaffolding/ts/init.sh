#!/usr/bin/env bash
npm init -y > /dev/null
npm pkg set scripts.start="tsx src/index.ts"
npm pkg set scripts.test="vitest"
npm install --save-dev tsx @types/node vitest
