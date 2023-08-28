import React, { useState } from "react";
import { useEffect } from "react";
import { SectionHeader } from "../../components/SectionHeader";
import { getNotes, saveNotesToFile } from "../../matlabComms/mainComms";

const Notes = ({ ...props }) => {
  // make a section with a big text box where you can type notes
  // with contenteditable
  // get date without time
  const date = new Date().toISOString().split("T")[0];
  const [notes, setNotes] = useState("");

  useEffect(() => {
    // fetch data from matlab
    const fetchData = async () => {
      const notes = await getNotes();
      setNotes(notes || `${date}\n\n`); // if notes is empty, set it to the date
    };
    fetchData();
  }, []);

  // save notes to file when notes change
  useEffect(() => {
    if (notes) saveNotesToFile(notes);
  }, [notes]);

  return (
    <div {...props}>
      <SectionHeader>Notes</SectionHeader>
      <textarea
        className="text-xs w-96 h-64 bg-gray-800 rounded-md p-4 focus:outline-none text-gray-100 border border-gray-600 border-opacity-0 hover:border-opacity-100 focus-within:border-blue-600 focus-within:outline-blue-600 overflow-y-scroll"
        value={notes}
        onChange={(e) => setNotes(e.target.value)}
      ></textarea>
    </div>
  );
};

export default Notes;
