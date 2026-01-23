#!/usr/bin/env bash
npm init -y
npm pkg set scripts.start="tsx src/index.ts"
npm install --save-dev tsx @types/node
