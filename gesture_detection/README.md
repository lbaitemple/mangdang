# Gesture Detection

It is recommended to train the models in your personal computer instead of the pupper.

### Install the dependencies
```
cd ~/generative_ai/gesture_detection/
pip install -r requirements.txt
```

### Run collect_imgs.py. When the program starts, press 'q' to start taking pictures of different angles of the specified class.
```
python collect_imgs.py
```

### Then run the programs to create the dataset and save the models
```
python create_dataset.py
python train.py
```

### Then navigate to the previous folder and run facial_expression.py or hand_gesture.py
```
python hand_gesture.py
```

## Testing
For testing, you can go to the directory called ```gesture_detection``` and run the Python files.

### hand_gesture.py
Run this command and start gesturing with your index finger pointing at different directions. Please, make sure there is no more than 1 hand in the frame of the camera and that the hand you want to gesture with is in frame with the camera intuitively. The pupper should look in those directions. You can make a fist for 5 seconds, upon which the program will quit automatically.
```
cd ~/generative_ai/gesture_detection/
python hand_gesture.py
```

### facial_expression.py
Run thus command and start making happy or sad faces with your face. Please, make sure there is no more than 1 face in the frame of the camera and that your face is in the frame of the camera intuitively. The pupper should change its LCD display to sad or happy based on your facial expressions. To quit the program, you can simply move out of the frame of the camera.
```
cd ~/generative_ai/gesture_detection/
python facial_expression.py
```
