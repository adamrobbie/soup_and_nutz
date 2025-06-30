import React, { useState, useRef, useEffect } from "react";

export default function ProfileDropdown() {
  const [open, setOpen] = useState(false);
  const ref = useRef();

  useEffect(() => {
    function handleClickOutside(event) {
      if (ref.current && !ref.current.contains(event.target)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div className="relative" ref={ref}>
      <button
        className="flex items-center space-x-2 focus:outline-none"
        onClick={() => setOpen((o) => !o)}
      >
        <span className="inline-block w-8 h-8 rounded-full bg-gradient-to-r from-purple-400 to-blue-500 flex items-center justify-center text-white font-bold">
          A
        </span>
        <span className="text-white font-medium">Profile</span>
        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      {open && (
        <div className="absolute right-0 mt-2 w-56 bg-gray-800 rounded shadow-lg z-50">
          <a href="/auth/profile" className="block px-4 py-2 text-gray-200 hover:bg-gray-700">Profile Settings</a>
          <a href="/auth/change_password" className="block px-4 py-2 text-gray-200 hover:bg-gray-700">Change Password</a>
          <form method="post" action="/auth/logout">
            <button type="submit" className="block w-full text-left px-4 py-2 text-gray-200 hover:bg-gray-700">Sign Out</button>
          </form>
        </div>
      )}
    </div>
  );
} 