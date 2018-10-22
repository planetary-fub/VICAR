      SUBROUTINE GETRES (LOC,CAMERA)
c 
c  routine to transfer nominal reseau locations to loc
c
      IMPLICIT INTEGER(A-Z)
      REAL*4 LOC(1)
      REAL*4 NLOC(2,202,8)
c
c    nominals for s/n 1 na (l,s)   
c
      REAL*4 LOC1(2,51)/
     *2.00,    6.80,   -7.94,   50.89,   -5.12,  126.13,
     *-5.47,  202.81,   -5.26,  280.45,   -4.37,  358.78,
     *-3.55,  437.10,   -1.30,  515.53,    1.80,  593.50,
     *3.30,  669.20,    5.00,  743.20,   13.90,  789.80,
     *6.84,   12.88,   16.19,   87.89,   15.13,  163.59,
     *15.11,  241.13,   15.63,  319.36,   16.52,  397.75,
     *17.82,  476.13,   19.50,  554.15,   22.07,  631.39,
     *25.84,  707.30,   23.04,  779.71,   46.50,    1.00,
     *44.30,   49.67,   43.24,  124.56,   43.21,  201.78,
     *43.67,  280.00,   44.40,  358.48,   45.43,  437.04,
     *46.70,  515.39,   48.48,  593.26,   51.20,  670.24,
     *55.40,  745.27,   59.80,  796.00,   82.09,   21.09,
     *81.34,   85.55,   81.41,  162.46,   81.96,  240.63,
     *82.69,  319.28,   83.47,  397.95,   84.48,  476.43,
     *85.83,  554.76,   87.61,  632.40,   90.39,  708.90,
     *94.11,  773.77,  120.63,   -0.63,  119.88,   47.13,
     *130.18,  747.38,  132.70,  795.50,  158.85,   18.56/
      REAL*4 LOD1(2,51)/
     *159.00,   84.49,  159.64,  162.22,  160.41,  240.83,
     *161.16,  319.76,  161.85,  398.59,  162.79,  477.26,
     *163.76,  555.59,  165.15,  633.45,  167.18,  710.43,
     *169.87,  775.99,  198.19,   -2.60,  198.12,   46.00,
     *207.45,  748.95,  209.50,  797.50,  237.44,   17.47,
     *237.95,   84.31,  238.76,  162.57,  239.56,  241.59,
     *240.28,  320.67,  240.94,  399.55,  241.73,  478.27,
     *242.62,  556.68,  243.77,  634.61,  245.45,  711.66,
     *247.70,  777.59,  277.03,   -3.27,  277.28,   45.65,
     *285.99,  750.35,  287.80,  799.20,  316.66,   17.23,
     *317.29,   84.57,  318.13,  163.36,  318.93,  242.63,
     *319.59,  321.80,  320.21,  400.77,  320.96,  479.53,
     *321.82,  557.93,  322.90,  635.89,  324.47,  713.02,
     *326.48,  779.11,  356.30,   -3.34,  356.50,   45.89,
     *365.09,  751.76,  366.80,  800.00,  395.64,   17.28,
     *396.43,   85.23,  397.31,  164.32,  398.09,  243.68,
     *398.75,  323.04,  399.39,  402.15,  400.13,  480.92/
      REAL*4 LOE1(2,51)/
     *401.06,  559.34,  402.19,  637.32,  403.69,  714.38,
     *405.58,  780.44,  434.97,   -3.18,  435.27,   46.29,
     *444.36,  753.15,  447.00,  800.00,  474.20,   17.83,
     *475.14,   86.00,  476.16,  165.31,  476.98,  244.94,
     *477.71,  324.38,  478.46,  403.45,  479.24,  482.37,
     *480.24,  560.74,  481.45,  638.65,  483.04,  715.69,
     *484.82,  781.61,  512.96,   -2.12,  513.57,   47.21,
     *523.58,  754.23,  524.25,  802.98,  551.81,   18.85,
     *553.30,   86.90,  554.57,  166.38,  555.64,  246.08,
     *556.49,  325.63,  557.39,  404.86,  558.24,  483.67,
     *559.34,  562.25,  560.65,  640.10,  562.29,  716.95,
     *563.98,  782.50,  589.69,   -1.06,  591.00,   48.30,
     *602.55,  755.13,  602.96,  803.30,  628.30,   20.21,
     *630.45,   88.15,  632.35,  167.36,  633.68,  247.20,
     *634.77,  326.82,  635.88,  406.15,  636.88,  485.05,
     *638.11,  563.49,  639.44,  641.30,  640.97,  717.77,
     *642.46,  782.78,  664.50,    1.00,  667.01,   49.86/
      REAL*4 LOF1(2,49)/
     *680.68,  755.29,  680.69,  803.03,  702.42,   22.78,
     *706.20,   89.83,  708.89,  168.79,  710.86,  248.35,
     *712.37,  327.88,  713.65,  407.28,  714.85,  486.16,
     *716.11,  564.48,  717.35,  641.95,  718.58,  717.92,
     *719.52,  782.06,  736.00,    1.00,  740.56,   52.64,
     *744.93,  130.07,  747.73,  209.20,  749.75,  288.70,
     *751.42,  368.15,  752.74,  447.18,  753.95,  525.72,
     *755.19,  603.64,  756.29,  680.07,  756.93,  754.29,
     *755.93,  804.20,  772.36,   17.91,  770.13,   92.06,
     *774.30,  170.10,  776.80,  249.32,  778.78,  328.73,
     *780.40,  407.98,  781.58,  486.75,  782.86,  564.89,
     *783.89,  641.88,  784.60,  717.05,  793.63,  788.25,
     *780.80,    7.80,  790.10,   55.10,  792.50,  131.20,
     *796.30,  209.90,  798.60,  289.20,  800.00,  368.50,
     *801.67,  446.95,  803.24,  525.36,  805.04,  602.90,
     *804.63,  679.29,  808.50,  752.75,  803.15,  797.77,
     *125.38,  594.17/
c
c  nominals for s/n 2 wa (l,s)
c
      REAL*4 LOC2(2,51)/
     *-1.66,   12.52,   -8.44,   58.37,   -5.94,  131.93,
     *-5.99,  208.32,   -5.64,  285.60,   -4.82,  363.76,
     *-4.40,  442.09,   -3.33,  520.67,   -1.79,  598.46,
     *1.00,  675.30,    2.00,  749.00,   10.00,  795.00,
     *8.24,   22.82,   15.17,   93.76,   14.51,  169.32,
     *14.67,  246.42,   15.31,  324.37,   15.93,  402.69,
     *16.71,  481.16,   17.70,  559.43,   19.42,  636.80,
     *22.39,  712.77,   19.25,  785.04,   44.30,    5.70,
     *43.05,   55.50,   42.49,  130.05,   42.66,  206.87,
     *43.21,  284.72,   43.90,  363.11,   44.54,  441.47,
     *45.14,  519.95,   46.10,  597.99,   47.88,  675.14,
     *51.24,  750.28,   55.30,  800.00,   80.90,   26.46,
     *80.58,   90.77,   81.03,  167.29,   81.63,  245.06,
     *82.22,  323.28,   82.65,  401.71,   83.19,  480.22,
     *83.74,  558.53,   84.54,  636.48,   86.37,  713.16,
     *89.34,  778.15,  119.20,    4.20,  119.20,   51.91,
     *125.31,  750.93,  127.20,  799.20,  158.20,   23.05/
      REAL*4 LOD2(2,51)/
     *158.56,   88.70,  159.41,  165.90,  160.01,  243.92,
     *160.48,  322.39,  160.72,  400.91,  160.98,  479.45,
     *161.20,  557.76,  161.67,  635.71,  162.49,  712.94,
     *164.14,  778.78,  197.60,    1.00,  197.72,   49.78,
     *201.69,  750.85,  202.80,  799.80,  237.22,   20.97,
     *237.87,   87.45,  238.57,  164.95,  239.09,  243.22,
     *239.41,  321.71,  239.46,  400.31,  239.51,  478.75,
     *239.51,  557.15,  239.63,  635.12,  240.08,  712.40,
     *241.02,  778.76,  277.30,    0.0 ,  277.21,   48.57,
     *279.48,  750.48,  280.20,  799.80,  316.91,   19.60,
     *317.40,   86.54,  318.01,  164.28,  318.37,  242.63,
     *318.50,  321.35,  318.44,  399.85,  318.35,  478.40,
     *318.08,  556.64,  318.04,  634.60,  318.31,  711.89,
     *318.88,  778.46,  356.78,   -1.60,  356.89,   47.51,
     *357.70,  749.82,  358.00,  799.20,  396.39,   18.45,
     *396.85,   85.63,  397.25,  163.76,  397.50,  242.22,
     *397.50,  320.92,  397.28,  399.61,  397.01,  478.05/
      REAL*4 LOE2(2,51)/
     *396.72,  556.34,  396.62,  634.26,  396.64,  711.45,
     *397.00,  777.88,  435.94,   -2.73,  436.16,   46.66,
     *435.92,  749.32,  436.20,  798.80,  475.43,   17.61,
     *475.85,   84.94,  476.29,  163.21,  476.45,  241.87,
     *476.25,  320.60,  475.93,  399.32,  475.59,  477.67,
     *475.36,  556.02,  475.02,  633.84,  475.01,  710.91,
     *475.35,  777.32,  514.44,   -3.28,  514.86,   45.78,
     *514.29,  748.71,  514.30,  797.90,  553.64,   16.88,
     *554.31,   84.37,  554.72,  162.67,  554.82,  241.50,
     *554.70,  320.36,  554.53,  399.04,  553.99,  477.54,
     *553.69,  555.68,  553.47,  633.52,  553.32,  710.36,
     *553.38,  776.50,  591.73,   -3.88,  592.78,   45.19,
     *592.16,  747.96,  591.80,  796.80,  630.67,   16.71,
     *631.89,   83.73,  632.54,  162.16,  632.74,  241.01,
     *632.65,  319.93,  632.52,  398.62,  632.06,  477.21,
     *631.73,  555.41,  631.41,  632.88,  631.06,  709.58,
     *630.76,  775.05,  667.57,   -3.48,  669.32,   45.07/
      REAL*4 LOF2(2,49)/
     *669.29,  746.41,  668.30,  794.30,  705.57,   17.41,
     *707.93,   83.63,  709.28,  161.51,  709.63,  240.56,
     *709.77,  319.54,  709.68,  398.27,  709.41,  476.63,
     *708.90,  554.66,  708.58,  632.09,  707.84,  708.18,
     *706.77,  772.49,  739.74,   -4.69,  743.38,   45.91,
     *746.16,  122.53,  747.53,  200.78,  747.89,  279.68,
     *747.88,  358.63,  747.72,  437.12,  747.42,  515.43,
     *746.95,  592.98,  746.11,  669.46,  744.67,  743.75,
     *742.30,  793.80,  775.91,   10.69,  772.02,   84.35,
     *774.62,  161.51,  775.69,  240.04,  776.08,  318.96,
     *776.10,  397.66,  775.78,  476.07,  775.36,  553.85,
     *774.52,  630.68,  773.06,  705.84,  779.60,  776.92,
     *784.70,    0.0 ,  792.80,   47.40,  793.30,  122.80,
     *795.40,  200.60,  796.50,  279.20,  796.90,  358.10,
     *796.70,  436.60,  796.30,  514.80,  795.50,  592.00,
     *794.30,  667.90,  795.50,  740.90,  789.40,  786.10,
     *122.65,  597.15/
c
c  nominals for s/n 3 na (l,s)
c
      REAL*4 LOC3(2,51)/
     *3.20,   12.00,   -3.97,   57.20,   -2.08,  130.28,
     *-2.56,  206.13,   -2.57,  282.97,   -1.99,  360.82,
     *-1.36,  439.05,   -0.25,  517.73,    1.00,  596.00,
     *4.20,  672.50,    6.20,  746.80,   15.10,  793.10,
     *13.11,   21.55,   19.24,   92.40,   18.16,  167.38,
     *17.89,  243.97,   18.21,  321.57,   18.70,  399.63,
     *19.60,  478.07,   20.75,  556.47,   22.79,  634.30,
     *26.42,  710.84,   23.89,  783.83,   48.30,    4.80,
     *47.00,   54.56,   46.05,  128.57,   45.80,  204.85,
     *46.03,  282.28,   46.49,  360.31,   47.13,  438.61,
     *47.90,  517.11,   49.25,  595.45,   51.50,  673.09,
     *55.48,  748.87,   60.20,  800.00,   84.58,   25.91,
     *83.99,   89.92,   83.99,  165.71,   84.25,  242.99,
     *84.70,  320.92,   85.08,  399.19,   85.69,  477.69,
     *86.50,  556.20,   87.72,  634.52,   90.06,  711.86,
     *93.61,  777.50,  122.80,    4.20,  122.49,   51.59,
     *129.27,  750.38,  131.80,  799.20,  161.35,   23.38/
      REAL*4 LOD3(2,51)/
     *161.42,   88.46,  161.88,  164.95,  162.31,  242.61,
     *162.73,  320.74,  163.00,  399.11,  163.34,  477.63,
     *163.80,  556.14,  164.52,  634.50,  165.92,  712.28,
     *168.34,  778.89,  200.50,    2.00,  200.45,   50.32,
     *205.49,  750.95,  207.20,  800.00,  239.70,   22.00,
     *240.06,   87.81,  240.66,  164.85,  241.11,  242.75,
     *241.41,  320.98,  241.58,  399.32,  241.81,  477.74,
     *242.01,  556.24,  242.39,  634.64,  243.31,  712.50,
     *244.90,  779.46,  279.10,    1.00,  279.26,   49.58,
     *283.01,  751.14,  284.50,  800.00,  318.60,   21.36,
     *319.11,   87.71,  319.63,  165.14,  320.06,  243.13,
     *320.24,  321.41,  320.31,  399.73,  320.44,  478.11,
     *320.54,  556.52,  320.85,  634.80,  321.53,  712.61,
     *322.68,  779.66,  358.00,    1.00,  358.29,   49.42,
     *361.34,  751.30,  362.50,  800.00,  397.45,   21.14,
     *398.00,   87.83,  398.51,  165.51,  398.83,  243.64,
     *399.05,  321.92,  399.06,  400.24,  399.13,  478.62/
      REAL*4 LOE3(2,51)/
     *399.23,  556.95,  399.47,  635.17,  400.00,  712.84,
     *401.04,  779.67,  436.70,    1.00,  437.01,   49.53,
     *439.78,  751.37,  440.80,  800.00,  476.01,   21.32,
     *476.65,   88.19,  477.18,  166.01,  477.50,  244.25,
     *477.64,  322.63,  477.74,  400.97,  477.75,  479.21,
     *477.88,  557.44,  478.20,  635.45,  478.71,  712.92,
     *479.56,  779.53,  515.00,    1.00,  515.45,   49.90,
     *518.51,  751.34,  519.20,  800.00,  554.10,   21.73,
     *554.98,   88.64,  555.61,  166.46,  555.99,  244.77,
     *556.19,  323.18,  556.30,  401.65,  556.43,  479.80,
     *556.61,  557.97,  556.95,  635.84,  557.50,  713.04,
     *558.31,  779.25,  592.60,    1.00,  593.27,   50.41,
     *597.08,  750.92,  597.80,  799.60,  631.31,   22.49,
     *632.61,   89.11,  633.55,  166.89,  634.09,  245.21,
     *634.41,  323.71,  634.72,  402.16,  634.90,  480.39,
     *635.21,  558.39,  635.56,  636.07,  635.99,  712.78,
     *636.40,  778.36,  668.70,    2.10,  670.07,   51.08/
      REAL*4 LOF3(2,49)/
     *675.05,  749.97,  674.90,  797.90,  706.80,   23.74,
     *709.05,   89.83,  710.59,  167.32,  711.53,  245.63,
     *712.10,  324.14,  712.52,  402.57,  712.94,  480.75,
     *713.36,  558.60,  713.63,  635.88,  713.73,  711.88,
     *713.45,  776.23,  741.70,    1.00,  744.93,   52.53,
     *747.75,  128.83,  749.32,  206.58,  750.20,  285.03,
     *750.92,  363.50,  751.46,  441.74,  751.80,  519.77,
     *752.12,  597.19,  752.20,  673.47,  751.66,  747.70,
     *750.50,  797.50,  778.30,   17.39,  773.98,   90.97,
     *776.57,  167.85,  778.01,  245.91,  778.94,  324.36,
     *779.65,  402.72,  780.12,  480.87,  780.49,  558.49,
     *780.64,  635.18,  780.17,  710.09,  787.69,  780.69,
     *787.20,    7.10,  795.30,   54.30,  795.70,  129.40,
     *798.10,  206.80,  799.50,  285.10,  800.00,  363.60,
     *801.00,  441.80,  801.00,  519.80,  801.50,  597.00,
     *801.50,  672.50,  803.80,  745.50,  797.90,  789.90,
     *125.42,  595.40/
c
C--NOMINALS FOR S/N 4 WA (L,S)
c
      REAL*4 LOC4(2,51)/
     : 23.36,   11.36,   14.22,   57.70,   11.42,  131.99,
     :  6.92,  209.29,    5.16,  287.55,    5.47,  366.80,
     :  3.15,  445.51,    1.76,  524.68,    0.87,  602.82,
     :  0.60,  679.82,   -2.54,  754.32,    4.02,  801.05,
     : 31.90,   21.73,   33.95,   93.86,   29.22,  170.12,
     : 26.80,  248.23,   24.97,  327.12,   23.88,  406.08,
     : 22.85,  484.97,   21.89,  563.74,   21.15,  641.12,
     : 21.08,  717.85,   13.01,  789.89,   67.82,    5.26,
     : 62.95,   55.88,   58.19,  131.10,   55.22,  208.97,
     : 53.80,  287.84,   52.19,  366.69,   51.26,  445.77,
     : 50.78,  524.27,   49.89,  602.86,   49.09,  680.15,
     : 48.90,  755.86,   51.26,  805.63,  100.88,   27.16,
     : 96.88,   92.16,   94.00,  169.17,   92.17,  247.96,
     : 91.11,  326.96,   90.05,  405.98,   89.71,  485.01,
     : 88.77,  563.79,   87.88,  641.94,   86.92,  719.01,
     : 86.19,  784.15,  139.15,    5.61,  135.90,   53.93,
     :124.94,  757.19,  126.26,  805.94,  174.92,   25.19/
      REAL*4 LOD4(2,51)/
     :172.14,   91.04,  170.74,  168.84,  169.30,  247.26,
     :168.83,  326.23,  168.00,  405.23,  167.72,  484.22,
     :166.86,  563.11,  165.91,  641.85,  164.74,  719.26,
     :163.72,  785.77,  214.00,    3.95,  211.95,   52.76,
     :203.17,  757.76,  204.12,  807.04,  251.21,   24.05,
     :249.81,   90.14,  248.19,  168.04,  247.83,  246.82,
     :247.10,  325.85,  246.82,  404.85,  246.10,  483.76,
     :245.66,  562.33,  244.86,  641.02,  243.24,  718.98,
     :242.09,  785.87,  291.12,    3.03,  289.71,   51.81,
     :282.15,  757.06,  282.08,  806.45,  329.11,   23.09,
     :327.92,   89.76,  326.91,  167.19,  326.17,  245.98,
     :325.89,  324.91,  325.28,  403.88,  325.06,  482.77,
     :324.66,  561.35,  323.88,  640.07,  322.75,  718.19,
     :321.16,  785.17,  369.17,    2.72,  367.91,   50.94,
     :361.76,  756.31,  361.41,  805.75,  407.74,   22.27,
     :406.30,   88.81,  405.79,  166.71,  405.00,  245.00,
     :404.84,  323.95,  404.26,  402.83,  404.03,  481.84/
      REAL*4 LOE4(2,51)/
     :403.64,  560.39,  402.95,  639.10,  401.94,  717.19,
     :400.76,  784.39,  447.27,    2.33,  446.23,   50.11,
     :440.92,  755.79,  440.63,  805.17,  486.09,   22.00,
     :485.12,   88.01,  484.26,  165.77,  483.92,  244.08,
     :483.26,  322.90,  483.11,  401.84,  482.94,  480.79,
     :482.66,  559.40,  481.94,  638.08,  481.00,  716.20,
     :479.96,  783.90,  525.81,    1.09,  525.04,   49.88,
     :519.92,  754.84,  519.30,  804.14,  564.86,   21.95,
     :564.02,   87.78,  563.15,  164.95,  562.84,  243.12,
     :562.18,  321.97,  562.02,  400.90,  561.84,  479.86,
     :561.21,  558.75,  560.90,  637.16,  559.90,  715.25,
     :558.30,  782.82,  604.17,    1.86,  603.33,   49.84,
     :598.15,  753.82,  597.29,  802.75,  642.71,   22.70,
     :642.16,   87.71,  641.85,  164.26,  641.13,  242.21,
     :640.93,  321.09,  640.77,  399.99,  640.07,  478.94,
     :639.91,  557.93,  639.05,  636.23,  637.95,  714.26,
     :636.15,  781.74,  681.02,    3.49,  681.03,   50.24/
      REAL*4 LOF4(2,49)/
     :675.70,  752.32,  673.82,  801.33,  719.10,   24.83,
     :719.23,   88.13,  719.19,  164.18,  719.00,  242.03,
     :718.79,  320.82,  718.21,  399.20,  717.96,  478.15,
     :717.22,  557.05,  716.26,  635.83,  714.89,  713.22,
     :712.19,  779.87,  755.55,    3.93,  756.92,   52.83,
     :757.34,  126.63,  757.25,  203.10,  757.14,  281.09,
     :757.05,  359.93,  756.81,  438.78,  756.06,  517.76,
     :755.12,  596.12,  753.77,  674.12,  750.96,  750.93,
     :747.91,  801.70,  792.05,   20.11,  784.93,   90.03,
     :785.76,  165.08,  785.81,  242.20,  785.37,  320.67,
     :785.08,  399.08,  784.80,  478.03,  783.95,  556.88,
     :782.18,  634.97,  779.97,  712.07,  784.23,  786.77,
     :802.74,   10.67,  808.14,   54.93,  806.05,  127.64,
     :806.62,  203.77,  806.72,  281.45,  806.67,  359.80,
     :806.16,  438.16,  805.39,  517.29,  803.23,  595.75,
     :801.60,  673.26,  801.48,  749.12,  793.68,  796.95,
     :127.08,  602.91/
c
C--NOMINALS FOR S/N 5 NA (L,S)
c
      REAL*4 LOC5(2,51)/
     : 12.22,   -1.58,    4.68,   45.14,    2.46,  120.47,
     : -1.08,  198.02,   -4.45,  276.76,   -6.19,  355.38,
     : -7.66,  433.37,   -8.24,  511.35,   -8.67,  588.41,
     : -7.75,  664.07,   -9.56,  736.91,   -2.67,  784.11,
     : 22.52,    7.48,   24.76,   81.58,   20.57,  158.75,
     : 17.37,  237.32,   15.15,  316.13,   13.36,  394.19,
     : 12.78,  472.22,   11.81,  549.73,   12.08,  626.28,
     : 13.37,  701.15,    5.85,  772.16,   57.33,   -7.43,
     : 54.26,   43.29,   49.95,  120.04,   46.87,  198.17,
     : 44.26,  276.99,   42.91,  355.77,   41.84,  433.92,
     : 40.93,  511.79,   40.17,  589.17,   40.92,  665.20,
     : 42.09,  739.89,   44.04,  790.06,   93.18,   14.99,
     : 89.68,   81.20,   86.70,  159.18,   84.14,  237.96,
     : 82.79,  316.89,   81.23,  395.18,   80.29,  473.77,
     : 79.82,  551.81,   79.79,  628.92,   79.84,  704.96,
     : 80.89,  769.16,  131.05,   -5.42,  129.26,   42.89,
     :119.06,  744.03,  119.57,  791.95,  169.11,   14.80/
      REAL*4 LOD5(2,51)/
     :166.35,   81.67,  164.17,  159.91,  162.83,  238.79,
     :161.71,  317.76,  160.68,  396.22,  159.91,  474.90,
     :159.05,  553.22,  158.17,  631.06,  158.14,  707.88,
     :158.21,  773.21,  207.88,   -5.67,  206.90,   43.09,
     :197.90,  746.98,  197.51,  795.71,  247.00,   14.99,
     :244.96,   82.11,  243.17,  160.71,  242.03,  239.19,
     :241.04,  318.28,  240.12,  397.16,  239.81,  475.93,
     :238.84,  554.23,  238.13,  632.73,  237.66,  709.93,
     :236.92,  775.96,  286.15,   -5.13,  285.20,   43.91,
     :277.07,  749.01,  276.51,  798.05,  325.93,   15.91,
     :324.07,   82.99,  322.79,  161.21,  321.77,  240.08,
     :320.88,  319.09,  319.97,  397.96,  319.18,  476.82,
     :318.31,  555.24,  317.92,  633.33,  317.12,  711.14,
     :316.18,  777.96,  365.42,   -4.23,  364.78,   44.88,
     :356.16,  749.94,  356.09,  799.65,  405.03,   16.87,
     :403.28,   83.91,  402.21,  162.05,  401.21,  240.86,
     :400.29,  319.77,  399.81,  398.33,  399.07,  477.13/
      REAL*4 LOE5(2,51)/
     :398.18,  555.94,  397.23,  634.09,  396.21,  712.09,
     :395.79,  779.03,  444.49,   -3.31,  444.00,   45.92,
     :435.74,  751.03,  434.91,  800.40,  484.24,   18.11,
     :483.04,   85.02,  482.04,  162.93,  480.85,  241.22,
     :480.15,  320.14,  479.20,  399.09,  478.86,  477.87,
     :477.91,  556.26,  476.97,  634.93,  475.95,  712.90,
     :474.76,  779.90,  523.73,   -1.58,  523.29,   47.11,
     :514.69,  751.70,  513.57,  800.48,  563.84,   19.97,
     :562.74,   86.19,  561.29,  163.99,  560.79,  242.25,
     :559.94,  320.97,  558.99,  399.85,  558.19,  478.30,
     :557.13,  557.03,  556.15,  635.26,  554.89,  713.20,
     :553.03,  780.11,  603.00,    0.51,  602.84,   49.01,
     :593.06,  752.00,  591.28,  800.82,  642.72,   22.30,
     :641.90,   88.05,  640.95,  165.05,  640.16,  243.17,
     :639.08,  321.78,  638.16,  400.21,  637.14,  479.01,
     :636.19,  557.91,  635.02,  636.03,  633.03,  713.81,
     :630.88,  780.10,  681.47,    3.78,  681.30,   51.76/
      REAL*4   LOF5(2,49)/
     :670.24,  751.96,  667.98,  800.56,  720.04,   26.17,
     :720.16,   90.85,  719.79,  166.90,  718.86,  244.27,
     :717.86,  322.83,  716.82,  401.13,  715.80,  480.00,
     :714.25,  558.34,  712.76,  636.74,  710.10,  713.82,
     :706.84,  779.17,  757.05,    6.07,  758.26,   55.81,
     :758.81,  129.94,  758.01,  206.28,  757.01,  284.08,
     :756.07,  362.73,  754.94,  441.05,  753.82,  519.97,
     :752.00,  598.09,  749.68,  675.26,  745.83,  750.93,
     :742.24,  802.81,  794.85,   23.87,  786.93,   93.92,
     :786.91,  168.94,  786.09,  245.99,  785.09,  323.85,
     :784.07,  402.23,  782.79,  480.94,  781.07,  559.21,
     :778.97,  636.99,  775.22,  713.27,  778.24,  786.08,
     :803.35,   12.77,  810.04,   58.41,  807.69,  131.43,
     :807.52,  207.59,  806.90,  285.00,  806.19,  363.04,
     :804.86,  441.23,  803.64,  519.62,  802.17,  597.94,
     :798.09,  675.50,  796.30,  749.17,  787.36,  796.14,
     :119.09,  591.27/
c
c  nominals for s/n 6 wa (l,s)
c
      REAL*4 LOC6(2,51)/
     *11.400,  14.300,   4.000,  59.300,   4.300, 131.700,
     *2.900, 207.200,   2.000, 284.100,   2.000, 362.000,
     *2.000, 439.900,   2.700, 517.800,   3.700, 595.200,
     *6.100, 671.400,   7.400, 744.700,  16.000, 790.000,
     *20.815,  23.325,  25.951,  93.427,  24.316, 168.319,
     *23.431, 245.044,  23.111, 322.626,  23.007, 400.590,
     *23.159, 478.651,  23.738, 556.514,  25.135, 633.454,
     *27.975, 709.045,  24.891, 780.183,  56.300,   5.800,
     *54.168,  55.309,  52.439, 129.390,  51.666, 205.824,
     *51.233, 283.265,  51.019, 361.235,  51.036, 439.351,
     *51.176, 517.566,  51.662, 595.286,  53.286, 671.932,
     *56.450, 746.433,  60.500, 796.600,  91.690,  26.410,
     *90.478,  90.379,  89.894, 166.539,  89.502, 244.088,
     *89.384, 322.069,  89.213, 400.219,  88.997, 478.375,
     *89.101, 556.347,  89.632, 633.919,  91.250, 710.136,
     *94.130, 774.537, 129.800,   4.200, 128.925,  51.960,
     *129.579, 748.038, 131.800, 795.800, 167.530,  23.319/
      REAL*4 LOD6(2,51)/
     *167.220,  88.658, 167.179, 165.603, 167.066, 243.383,
     *166.757, 321.795, 166.388, 400.089, 166.296, 478.254,
     *165.968, 556.311, 165.991, 633.976, 166.652, 710.712,
     *168.282, 775.973, 206.400,   1.200, 205.920,  50.121,
     *205.615, 748.731, 206.800, 797.100, 245.008,  21.703,
     *245.138,  87.931, 245.182, 165.305, 245.248, 243.393,
     *245.039, 321.801, 244.482, 400.082, 244.213, 478.199,
     *243.757, 556.350, 243.562, 634.074, 243.852, 711.016,
     *244.760, 776.713, 283.700,   0.500, 284.160,  49.334,
     *283.206, 749.060, 283.800, 797.800, 323.174,  20.850,
     *323.502,  87.502, 323.731, 165.390, 323.667, 243.686,
     *323.444, 322.064, 323.168, 400.326, 322.573, 478.521,
     *322.147, 556.596, 321.858, 634.208, 322.063, 711.112,
     *322.538, 777.066, 362.000,  -0.500, 362.632,  49.051,
     *361.404, 749.250, 361.800, 798.000, 401.674,  20.505,
     *402.137,  87.317, 402.287, 165.443, 402.281, 243.797,
     *401.969, 322.292, 401.495, 400.488, 401.242, 478.694/
      REAL*4 LOE6(2,51)/
     *400.633, 556.775, 400.487, 634.278, 400.470, 711.272,
     *400.858, 777.194, 440.000,  -1.000, 441.158,  48.772,
     *439.889, 749.237, 440.200, 798.000, 480.004,  20.105,
     *480.494,  87.364, 480.897, 165.476, 480.721, 244.050,
     *480.461, 322.513, 480.221, 400.741, 479.646, 479.094,
     *479.404, 557.004, 479.223, 634.356, 479.208, 711.265,
     *479.489, 776.951, 517.700,  -1.500, 519.307,  48.685,
     *518.670, 749.061, 518.800, 797.300, 558.086,  20.263,
     *558.826,  87.262, 559.215, 165.353, 559.277, 244.005,
     *559.119, 322.575, 558.790, 401.063, 558.398, 479.208,
     *558.218, 557.191, 558.062, 634.491, 558.078, 711.117,
     *558.117, 776.444, 595.500,  -1.500, 597.157,  48.607,
     *597.167, 748.209, 596.800, 796.200, 635.135,  20.328,
     *636.428,  87.276, 637.235, 165.345, 637.383, 243.900,
     *637.288, 322.507, 637.235, 401.059, 637.000, 479.335,
     *636.626, 557.187, 636.460, 634.377, 636.312, 710.363,
     *636.221, 775.107, 671.800,  -1.000, 674.024,  48.819/
      REAL*4 LOF6(2,49)/
     *674.865, 746.970, 674.000, 794.000, 710.290,  21.315,
     *712.586,  87.320, 714.145, 165.050, 714.747, 243.582,
     *715.086, 322.319, 715.160, 400.759, 714.817, 479.073,
     *714.612, 556.702, 714.349, 633.562, 713.678, 708.953,
     *712.639, 772.477, 743.800,  -1.000, 748.337,  49.624,
     *751.218, 126.001, 752.441, 204.101, 753.245, 282.675,
     *753.414, 361.384, 753.379, 439.674, 753.322, 517.523,
     *752.835, 594.804, 752.285, 670.433, 750.784, 743.998,
     *748.800, 793.200, 781.256,  14.731, 777.199,  87.795,
     *779.634, 164.962, 781.117, 243.301, 781.632, 321.858,
     *781.817, 400.335, 781.634, 478.407, 781.489, 555.766,
     *780.641, 632.174, 779.385, 706.410, 785.865, 776.276,
     *790.300,   3.900, 798.200,  50.800, 799.000, 126.200,
     *801.000, 204.400, 802.000, 282.000, 803.000, 360.000,
     *803.000, 438.000, 803.000, 516.000, 803.000, 593.000,
     *803.000, 670.000, 803.000, 742.000, 796.000, 785.600,
     *127.419, 595.250 /
c     ,   0.000,   0.000,   0.000,   0.000/
c
c  nominals for s/n 7 na (l,s)
c
      REAL*4 LOC7(2,51)/
     *3.600,  11.400,  -1.000,  50.500,   1.000, 125.600,
     *0.0  , 204.200,  -2.000, 281.000,  -2.000, 361.000,
     *-2.000, 440.000,  -2.000, 518.000,   2.600, 596.300,
     *5.500, 673.500,   7.000, 748.000,  15.600, 794.500,
     *14.438,  21.490,  20.630,  91.796,  19.295, 166.784,
     *19.037, 243.643,  19.252, 321.486,  19.700, 399.899,
     *20.597, 478.595,  22.117, 557.270,  24.217, 635.298,
     *27.780, 711.835,  24.942, 784.605,  50.600,   4.700,
     *48.817,  54.013,  47.589, 127.859,  47.275, 204.288,
     *47.376, 281.917,  47.690, 360.413,  48.397, 438.982,
     *49.299, 517.772,  50.613, 596.433,  53.094, 674.025,
     *57.114, 749.643,  61.500, 799.700,  86.675,  25.645,
     *85.807,  89.241,  85.631, 165.041,  85.749, 242.475,
     *86.141, 320.759,  86.449, 399.494,  87.190, 478.367,
     *88.021, 557.135,  89.417, 635.436,  91.804, 712.741,
     *95.406, 778.151, 125.100,   3.900, 124.507,  51.035,
     *131.266, 751.018, 133.700, 799.300, 163.446,  22.805/
      REAL*4 LOD7(2,51)/
     *163.426,  87.704, 163.728, 164.237, 164.124, 242.123,
     *164.451, 320.537, 164.688, 399.352, 165.214, 478.254,
     *165.665, 557.073, 166.560, 635.545, 168.212, 713.252,
     *170.451, 779.385, 202.800,   1.200, 202.662,  49.529,
     *207.913, 751.699, 209.700, 799.800, 242.218,  21.359,
     *242.426,  86.861, 242.778, 164.059, 243.252, 242.226,
     *243.465, 320.784, 243.592, 399.621, 243.898, 478.464,
     *244.297, 557.312, 244.780, 635.781, 245.903, 713.575,
     *247.651, 780.119, 281.900,   0.0  , 281.763,  48.725,
     *285.887, 752.094, 287.500, 801.000, 321.306,  20.654,
     *321.696,  86.758, 322.227, 164.304, 322.469, 242.673,
     *322.650, 321.266, 322.729, 400.003, 322.911, 478.802,
     *323.109, 557.535, 323.623, 636.062, 324.483, 713.837,
     *325.843, 780.519, 360.900,   0.0  , 361.081,  48.717,
     *364.479, 752.363, 366.000, 802.000, 400.335,  20.451,
     *400.892,  86.944, 401.317, 164.732, 401.553, 243.089,
     *401.687, 321.747, 401.723, 400.521, 401.858, 479.387/
      REAL*4 LOE7(2,51)/
     *402.212, 558.074, 402.529, 636.542, 403.294, 714.238,
     *404.454, 780.709, 439.600,   0.0  , 440.021,  48.727,
     *443.165, 752.715, 443.800, 801.800, 479.020,  20.700,
     *479.664,  87.355, 480.247, 165.158, 480.417, 243.601,
     *480.487, 322.462, 480.598, 401.218, 480.662, 479.892,
     *480.922, 558.503, 481.398, 636.761, 482.026, 714.405,
     *482.966, 780.629, 517.800,   0.0  , 518.489,  49.136,
     *521.813, 752.616, 522.800, 801.000, 557.033,  21.197,
     *557.988,  87.767, 558.633, 165.622, 558.987, 244.197,
     *559.177, 322.948, 559.310, 401.685, 559.375, 480.575,
     *559.633, 559.067, 560.028, 637.207, 560.633, 714.516,
     *561.273, 780.495, 595.100,   1.000, 596.140,  49.629,
     *600.047, 752.211, 600.600, 799.800, 633.719,  22.141,
     *635.307,  88.446, 636.354, 166.123, 636.816, 244.591,
     *637.191, 323.523, 637.419, 402.300, 637.548, 480.949,
     *637.853, 559.461, 638.254, 637.416, 638.640, 714.090,
     *638.187, 779.497, 670.200,   2.200, 672.326,  50.597/
      REAL*4 LOF7(2,49)/
     *677.278, 751.005, 677.200, 798.700, 708.316,  23.759,
     *710.897,  89.334, 712.693, 166.693, 713.738, 245.062,
     *714.356, 323.739, 714.692, 402.645, 714.986, 481.290,
     *715.366, 559.554, 715.543, 636.935, 715.580, 712.900,
     *714.155, 777.087, 742.200,   1.300, 745.992,  52.466,
     *749.263, 128.376, 750.974, 206.008, 751.984, 284.536,
     *752.618, 363.334, 753.083, 441.916, 753.417, 520.414,
     *753.569, 597.996, 753.477, 674.483, 752.224, 748.661,
     *751.700, 798.300, 778.297,  17.630, 774.704,  90.703,
     *777.662, 167.286, 779.388, 245.362, 780.336, 323.903,
     *780.899, 402.593, 781.313, 481.170, 781.536, 559.044,
     *781.489, 635.833, 780.821, 710.751, 787.184, 781.331,
     *787.800,   7.800, 795.700,  54.000, 796.600, 128.800,
     *799.000, 206.200, 800.500, 284.200, 801.759, 363.098,
     *802.114, 441.479, 802.692, 519.692, 803.446, 597.012,
     *801.835, 673.175, 803.849, 746.237, 798.300, 790.600,
     *127.172, 596.300/
c   ,   0.000,   0.000,   0.000,   0.000/
c
c  nominals for s/n 8 wa (l,s)
c
      REAL*4 LOC8(2,51)/
     *10.200,  13.200,   3.000,  59.000,   4.300, 132.500,
     *2.900, 208.200,   2.000, 284.800,   1.800, 362.500,
     *1.500, 440.500,   2.000, 518.800,   2.800, 596.700,
     *4.500, 673.800,   4.000, 749.100,  11.400, 796.000,
     *20.163,  23.182,  26.123,  94.655,  24.031, 169.562,
     *22.938, 245.933,  22.314, 323.268,  22.170, 401.288,
     *22.277, 479.385,  22.788, 557.465,  24.051, 635.120,
     *25.904, 711.767,  21.222, 785.423,  56.100,   6.700,
     *54.222,  56.707,  52.347, 130.713,  51.193, 206.831,
     *50.591, 284.122,  50.280, 361.896,  50.250, 440.029,
     *50.282, 518.281,  50.795, 596.300,  52.142, 673.626,
     *54.352, 749.642,  57.800, 800.000,  91.879,  28.264,
     *90.431,  92.074,  89.512, 167.688,  89.082, 244.675,
     *88.667, 322.482,  88.347, 400.555,  88.298, 478.910,
     *88.360, 557.261,  88.780, 635.205,  90.204, 712.259,
     *92.168, 777.952, 129.900,   6.400, 128.988,  53.819,
     *128.540, 750.444, 130.200, 799.200, 167.682,  25.613/
      REAL*4 LOD8(2,51)/
     *167.138,  90.432, 166.824, 166.594, 166.466, 244.103,
     *166.255, 322.124, 165.727, 400.372, 165.518, 478.666,
     *165.334, 557.037, 165.374, 635.125, 165.863, 712.465,
     *165.800, 778.500, 206.500,   4.200, 206.188,  52.351,
     *204.760, 750.753, 206.000, 800.000, 245.345,  24.233,
     *245.157,  89.530, 244.938, 166.235, 244.725, 243.833,
     *244.436, 321.985, 243.866, 400.225, 243.522, 478.583,
     *243.254, 556.918, 242.918, 635.050, 243.164, 712.637,
     *243.913, 779.048, 284.400,   3.100, 284.348,  51.528,
     *282.317, 750.742, 283.000, 800.000, 323.634,  23.441,
     *323.548,  89.136, 323.488, 166.195, 323.307, 243.885,
     *322.829, 322.095, 322.327, 400.258, 321.914, 478.614,
     *321.495, 556.858, 321.232, 634.894, 321.097, 712.400,
     *321.560, 779.020, 363.000,   2.500, 362.961,  51.117,
     *360.344, 750.836, 360.800, 800.000, 402.178,  23.064,
     *402.222,  89.022, 402.161, 166.115, 401.828, 243.975,
     *401.401, 322.199, 400.836, 400.465, 400.400, 478.733/
      REAL*4 LOE8(2,51)/
     *399.921, 557.022, 399.535, 634.953, 399.404, 712.420,
     *399.533, 778.899, 441.200,   2.200, 441.281,  50.984,
     *438.552, 750.323, 438.800, 799.600, 480.223,  23.161,
     *480.451,  89.086, 480.453, 166.284, 480.342, 244.214,
     *479.823, 322.394, 479.369, 400.616, 478.811, 478.872,
     *478.370, 557.024, 478.055, 634.854, 477.738, 712.013,
     *477.802, 778.193, 518.800,   2.700, 519.283,  51.136,
     *516.914, 749.833, 516.800, 798.700, 557.534,  23.592,
     *558.318,  89.360, 558.529, 166.450, 558.445, 244.379,
     *558.153, 322.630, 557.739, 400.786, 557.293, 478.999,
     *556.782, 557.094, 556.455, 634.659, 556.144, 711.458,
     *555.713, 777.414, 595.200,   3.200, 596.271,  51.753,
     *594.989, 748.797, 594.500, 797.000, 633.704,  24.402,
     *635.144,  89.669, 635.925, 166.673, 636.159, 244.568,
     *635.964, 322.660, 635.746, 400.869, 635.382, 479.016,
     *634.889, 556.846, 634.489, 634.300, 634.001, 710.512,
     *633.346, 775.290, 670.200,   4.500, 671.937,  52.587/
      REAL*4 LOF8(2,49)/
     *672.025, 746.917, 671.300, 794.500, 707.793,  25.916,
     *710.237,  90.672, 711.914, 167.130, 712.699, 244.690,
     *712.959, 322.725, 712.993, 400.828, 712.673, 478.782,
     *712.263, 556.296, 711.609, 633.317, 710.627, 708.560,
     *709.470, 772.415, 741.800,   3.900, 745.307,  54.267,
     *748.215, 129.319, 749.843, 205.991, 750.682, 283.690,
     *751.007, 361.751, 751.012, 439.670, 750.636, 517.344,
     *749.978, 594.293, 748.918, 670.044, 747.388, 743.849,
     *745.600, 793.600, 777.945,  19.603, 773.763,  91.780,
     *776.371, 167.603, 777.821, 244.862, 778.618, 322.679,
     *779.010, 400.657, 778.796, 478.357, 778.381, 555.465,
     *777.375, 631.378, 775.818, 705.924, 782.231, 776.552,
     *787.600,   9.500, 795.000,  55.200, 795.200, 129.400,
     *797.500, 206.200, 799.000, 283.800, 800.000, 361.700,
     *800.000, 439.300, 800.000, 516.700, 800.000, 593.200,
     *797.500, 668.700, 799.000, 741.500, 792.700, 786.300,
     *126.645, 596.277/
c
c    NLOC(2,102,8)  
c
      EQUIVALENCE (NLOC(1,  1,1),LOC1),(NLOC(1, 52,1),LOD1)
      EQUIVALENCE (NLOC(1,103,1),LOE1),(NLOC(1,154,1),LOF1)
c
      EQUIVALENCE (NLOC(1,1,2),LOC2),(NLOC(1,52,2),LOD2)
      EQUIVALENCE (NLOC(1,103,2),LOE2),(NLOC(1,154,2),LOF2)
c
      EQUIVALENCE (NLOC(1,1,3),LOC3),(NLOC(1,52,3),LOD3)
      EQUIVALENCE (NLOC(1,103,3),LOE3),(NLOC(1,154,3),LOF3)
c
      EQUIVALENCE (NLOC(1,  1,4),LOC4),(NLOC(1, 52,4),LOD4)
      EQUIVALENCE (NLOC(1,103,4),LOE4),(NLOC(1,154,4),LOF4)
c
      EQUIVALENCE (NLOC(1,  1,5),LOC5),(NLOC(1, 52,5),LOD5)
      EQUIVALENCE (NLOC(1,103,5),LOE5),(NLOC(1,154,5),LOF5)
c
      EQUIVALENCE (NLOC(1,  1,6),LOC6),(NLOC(1, 52,6),LOD6)
      EQUIVALENCE (NLOC(1,103,6),LOE6),(NLOC(1,154,6),LOF6)
c
      EQUIVALENCE (NLOC(1,  1,7),LOC7),(NLOC(1, 52,7),LOD7)
      EQUIVALENCE (NLOC(1,103,7),LOE7),(NLOC(1,154,7),LOF7)
c
      EQUIVALENCE (NLOC(1,  1,8),LOC8),(NLOC(1, 52,8),LOD8)
      EQUIVALENCE (NLOC(1,103,8),LOE8),(NLOC(1,154,8),LOF8)
c
      Call MVE(7, 404, NLOC(1,1,Camera), LOC, 1, 1)
c
      Return
      End
