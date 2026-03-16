#!/bin/bash
memory_pressure | grep -o '[0-9]*%' | head -1
