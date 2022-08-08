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
const {MergeVideoLibrary} = ReactNative.NativeModules;


const App = () => {
  const isDarkMode = useColorScheme() === 'dark';
  const handlePress = async () => {
    const audioPath = RNFetchBlob.fs.dirs.MainBundleDir + 'audio.flac'
    const videoPath = RNFetchBlob.fs.dirs.MainBundleDir + 'vid1.mov'
    // const res = await RNFetchBlob.fs.ls(audioPath)
    // console.log('res', res)
    const result = MergeVideoLibrary.mergeVideo(audioPath, videoPath)
    console.log('result', result)
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
