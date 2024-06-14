import React, { useState } from 'react';
import { SectionHeader } from '../components/SectionHeader';
import { Generate_Hadamard, Acquire_Hadamard_ZStack_Triggered } from "../matlabComms/hadamardComms";

const Hadamard = ({ deviceName = [] }) => {
 const [folderName, setFolderName] = useState('');
 const [thickness, setThickness] = useState('');
 const [numSlices, setNumSlices] = useState('');

 const handleButtonClick = () => {
   Generate_Hadamard().then((success) => {
     if (!success) {
       alert('Hadamard patterns not generated. Sad!');
     } else {
       alert('Hadamard patterns generated and sent to DMD. Enjoy the show!');
     }
   });
 };

 const handleAcquireButtonClick = () => {
   Acquire_Hadamard_ZStack_Triggered(thickness, numSlices, folderName)
     .then((success) => {
      console.log('Acquire_Hadamard_ZStack_Triggered success:', success);
       if (!success) {
         alert('Failed to acquire Hadamard Z-Stack.');
       } else {
         alert('Successfully acquired Hadamard Z-Stack.');
       }
     })
     .catch((error) => {
       console.error('Error acquiring Hadamard Z-Stack:', error);
       alert('Error acquiring Hadamard Z-Stack.');
     });
 };

 return (
   <div>
     <SectionHeader></SectionHeader>
     <button onClick={handleButtonClick}>Generate Hadamard patterns</button>

     <div>
       <input
         type="text"
         placeholder="Folder Name"
         value={folderName}
         onChange={(e) => setFolderName(e.target.value)}
       />
       <input
         type="text"
         placeholder="Thickness"
         value={thickness}
         onChange={(e) => setThickness(e.target.value)}
       />
       <input
         type="text"
         placeholder="Number of Slices"
         value={numSlices}
         onChange={(e) => setNumSlices(e.target.value)}
       />
       <button onClick={handleAcquireButtonClick}>Acquire Hadamard Z-Stack</button>
     </div>
   </div>
 );
};

export default Hadamard;