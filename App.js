import React from 'react';
import ReactNative, {
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  useColorScheme,
  View,
} from 'react-native';
import RNFetchBlob from 'rn-fetch-blob';
const {MergeVideo} = ReactNative.NativeModules;


const App = () => {
  const isDarkMode = useColorScheme() === 'dark';
  const handlePress = async () => {
    const audioPath = 'file://' + RNFetchBlob.fs.dirs.MainBundleDir + '/audio.flac'
    const videoPath = 'file://' + RNFetchBlob.fs.dirs.MainBundleDir + '/IMG_0142.MOV'
    console.log('audioPath exist', await RNFetchBlob.fs.exists(audioPath))
    console.log('videoPath exist', await  RNFetchBlob.fs.exists(videoPath))
    // const res = await RNFetchBlob.fs.ls(audioPath)
    // console.log('res', res)
    // const cb = (response) => { console.log('response', response)}
    const cb = (response) => { alert(response)}
    const result = MergeVideo.mergeVideo(videoPath, audioPath, cb, (error) => { 
      alert(error);
    })
    // console.log('result', result)
  }
  return (
    <SafeAreaView style={{flex: 1}}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <View style={{ flex: 1, backgroundColor: 'biege', paddingHorizontal: 20, paddingVertical: 10 }}>
        <TouchableOpacity style={{ backgroundColor: '#999', paddingHorizontal: 10, paddingVertical: 20, borderRadius: 30, alignItems: 'center' }} onPress={handlePress}>
          <Text>Merge video & audio</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
};


export default App;
