#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'
require 'TT_Lib2/system.rb'

# @since 2.5.0
module TT::Win32
  
  if TT::System.is_windows?
    #require 'win32/api'
    require File.join( TT::Lib.path, 'libraries', 'win32', 'tt_api' )
    
    # Window Styles
    # http://msdn.microsoft.com/en-us/library/czada357.aspx
    # http://msdn.microsoft.com/en-us/library/ms632680%28VS.85%29.aspx
    # http://msdn.microsoft.com/en-us/library/ms632600%28v=vs.85%29.aspx
    WS_CAPTION      = 0x00C00000
    WS_SYSMENU      = 0x00080000
    WS_MAXIMIZEBOX  = 0x10000
    WS_MINIMIZEBOX  = 0x20000
    WS_SIZEBOX      = 0x40000
    WS_POPUP        = 0x80000000

    WS_EX_TOOLWINDOW = 0x00000080
    WS_EX_NOACTIVATE = 0x08000000
    
    # GetWindowLong() flags
    # http://msdn.microsoft.com/en-us/library/ms633584%28v=vs.85%29.aspx
    GWL_STYLE   = -16
    GWL_EXSTYLE = -20

    # SetWindowPos() flags
    # http://msdn.microsoft.com/en-us/library/ms633545%28v=vs.85%29.aspx
    SWP_NOSIZE       = 0x0001
    SWP_NOMOVE       = 0x0002
    SWP_NOACTIVATE   = 0x0010
    SWP_DRAWFRAME    = 0x0020
    SWP_FRAMECHANGED = 0x0020
    SWP_NOREPOSITION = 0x0200
    
    HWND_BOTTOM     =  1
    HWND_TOP        =  0
    HWND_TOPMOST    = -1
    HWND_NOTOPMOST  = -2
    
    # GetWindow() flags
    # http://msdn.microsoft.com/en-us/library/ms633515%28v=vs.85%29.aspx
    #GW_HWNDFIRST    = 0
    #GW_HWNDLAST     = 1
    #GW_HWNDNEXT     = 2
    #GW_HWNDPREV     = 3
    #GW_OWNER        = 4 
    #GW_CHILD        = 5
    #GW_ENABLEDPOPUP = 6
    
    # GetAncestor() flags
    # http://msdn.microsoft.com/en-us/library/ms633502%28v=vs.85%29.aspx
    GA_PARENT     = 1
    GA_ROOT       = 2
    GA_ROOTOWNER  = 3
    
    # PeekMessage() flags
    PM_NOREMOVE = 0x0000 # Messages are not removed from the queue after processing by PeekMessage.
    PM_REMOVE   = 0x0001 # Messages are removed from the queue after processing by PeekMessage.
    PM_NOYIELD  = 0x0002 # Prevents the system from releasing any thread that is waiting for the caller to go idle (see WaitForInputIdle).
    
    
    # Windows Functions
    # L = Long (includes hwnd)
    # I = Integer
    # P = Pointer
    # V = Void
    #FindWindow     = API.new('FindWindow'   , 'PP' , 'L', 'user32')
    #FindWindowEx   = API.new('FindWindowEx' , 'LLPP', 'L', 'user32')
    #GetForegroundWindow = API.new('GetForegroundWindow', '', 'L', 'user32')
    #GetParent           = API.new('GetParent' , 'LI', 'L', 'user32')
    #GetWindow           = API.new('GetWindow' , 'LI', 'L', 'user32')
    GetAncestor         = API.new('GetAncestor' , 'LI', 'L', 'user32')
    
    # http://msdn.microsoft.com/en-us/library/ms646292%28v=vs.85%29.aspx
    # http://blogs.msdn.com/b/oldnewthing/archive/2008/10/06/8969399.aspx
    #
    # The return value is the handle to the active window attached to the calling
    # thread's message queue. Otherwise, the return value is NULL.
    #
    # To get the handle to the foreground window, you can use GetForegroundWindow. 
    GetActiveWindow     = API.new('GetActiveWindow', '', 'L', 'user32')
    
    # http://msdn.microsoft.com/en-us/library/ms646311%28v=vs.85%29.aspx
    SetActiveWindow     = API.new('SetActiveWindow', 'L', 'L', 'user32')
    
    # http://msdn.microsoft.com/en-us/library/ms646294%28v=vs.85%29.aspx
    #GetFocus            = API.new('GetFocus', '', 'L', 'user32')
    
    SetWindowPos        = API.new('SetWindowPos' , 'LLIIIII', 'I', 'user32')
    SetWindowLong       = API.new('SetWindowLong', 'LIL', 'L', 'user32')
    GetWindowLong       = API.new('GetWindowLong', 'LI' , 'L', 'user32')
    GetWindowText       = API.new('GetWindowText', 'LPI', 'I', 'user32')
    GetWindowTextLength = API.new('GetWindowTextLength', 'L', 'I', 'user32')
    
    # http://msdn.microsoft.com/en-us/library/ms644943%28v=vs.85%29.aspx
    PeekMessage         = API.new('PeekMessage' , 'PLIII', 'I', 'user32')
    
    OutputDebugString   = API.new('OutputDebugString', 'P', 'V', 'kernel32')
  end
  
  
  # (i)
  # To obtain a window's owner window, instead of using GetParent, use GetWindow
  # with the GW_OWNER flag. To obtain the parent window and not the owner,
  # instead of using GetParent, use GetAncestor with the GA_PARENT flag.
  
  
  #(i)
  # FindWindowLike
  # http://support.microsoft.com/kb/147659
  
  # EnumChildWindows
  # http://msdn.microsoft.com/en-us/library/ms633494%28v=vs.85%29.aspx
  # http://stackoverflow.com/questions/3327666/win32s-findwindow-can-find-a-particular-window-with-the-exact-title-but-what
  
  
  # @return [Boolean]
  # @since 2.6.0
  def self.activate_sketchup_window
    hwnd = self.get_sketchup_window
    return false unless hwnd
    SetActiveWindow.call( hwnd )
  end
  
  # Returns the window handle of the SketchUp window for the input queue of the
  # calling ruby method.
  #
  # @todo Update with a method that get the SketchUp window regardless if it has focus.
  #
  # @return [Integer] Returns a window handle on success or +nil+ on failure
  # @since 2.5.0
  def self.get_sketchup_window
    hwnd = GetActiveWindow.call
    return nil if hwnd.nil?
    # In case the SketchUp window was not the active one - get the ancestor.
    GetAncestor.call(hwnd, GA_ROOTOWNER)
  end
  
  
  # @param [Integer] hwnd
  #
  # @return [String|Nil]
  # @since 2.5.0
  def self.get_window_text(hwnd)
    # Create a string buffer for the window text.
    buf_len = GetWindowTextLength.call(hwnd)
    return nil if buf_len == 0
    str = ' ' * (buf_len + 1)
    # Retreive the text.
    result = GetWindowText.call(hwnd, str, str.length)
    return nil if result == 0
    str.strip
  end
  
  
  # Call after webdialog.show to change the window into a toolwindow. Spesify the
  # window title so the method can verify it changes the correct window.
  #
  # @param [String] window_title
  #
  # @return [Nil]
  # @since 2.5.0
  def self.make_toolwindow_frame(window_title)
    # Retrieves the window handle to the active window attached to the calling
    # thread's message queue. 
    hwnd = GetActiveWindow.call
    return nil if hwnd.nil?
    
    # Verify window text as extra security to ensure it's the correct window.
    buf_len = GetWindowTextLength.call(hwnd)
    return nil if buf_len == 0
    
    str = ' ' * (buf_len + 1)
    result = GetWindowText.call(hwnd, str, str.length)
    return nil if result == 0
    
    return nil unless str.strip == window_title.strip
    
    # Set frame to Toolwindow
    style = GetWindowLong.call(hwnd, GWL_EXSTYLE)
    return nil if style == 0
    
    new_style = style | WS_EX_TOOLWINDOW
    result = SetWindowLong.call(hwnd, GWL_EXSTYLE, new_style)
    return nil if result == 0
    
    # Remove and disable minimze and maximize
    # http://support.microsoft.com/kb/137033
    style = GetWindowLong.call(hwnd, GWL_STYLE)
    return nil if style == 0
    
    style = style & ~WS_MINIMIZEBOX
    style = style & ~WS_MAXIMIZEBOX
    result = SetWindowLong.call(hwnd, GWL_STYLE,  style)
    return nil if result == 0
    
    # Refresh the window frame
    # (!) SWP_NOZORDER | SWP_NOOWNERZORDER
    flags = SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE
    result = SetWindowPos.call(hwnd, 0, 0, 0, 0, 0, flags)
    result != 0
  end
  
  
  # Removes the Min and Max button.
  #
  # Call after webdialog.show to change the window into a toolwindow. Spesify the
  # window title so the method can verify it changes the correct window.
  #
  # @param [String] window_title
  #
  # @return [Nil]
  # @since 2.6.0
  def self.window_no_resize( window_title )
    # Retrieves the window handle to the active window attached to the calling
    # thread's message queue. 
    hwnd = GetActiveWindow.call
    return nil if hwnd.nil?
    
    # Verify window text as extra security to ensure it's the correct window.
    buf_len = GetWindowTextLength.call(hwnd)
    return nil if buf_len == 0
    
    str = ' ' * (buf_len + 1)
    result = GetWindowText.call(hwnd, str, str.length)
    return nil if result == 0
    
    return nil unless str.strip == window_title.strip
    
    # Remove and disable minimze and maximize
    # http://support.microsoft.com/kb/137033
    style = GetWindowLong.call(hwnd, GWL_STYLE)
    return nil if style == 0
    
    style = style & ~WS_MINIMIZEBOX
    style = style & ~WS_MAXIMIZEBOX
    result = SetWindowLong.call(hwnd, GWL_STYLE,  style)
    return nil if result == 0
    
    # Refresh the window frame
    # (!) SWP_NOZORDER | SWP_NOOWNERZORDER
    flags = SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE
    result = SetWindowPos.call(hwnd, 0, 0, 0, 0, 0, flags)
    result != 0
  end
  
  
  # Allows the SketchUp process to process it's queued messages. Avoids whiteout.
  #
  # @return [Boolean]
  # @since 2.5.0
  def self.refresh_sketchup
    msg = "\000" * 36 # Size of struct MSG (!) Make WinStruct wrapper
    PeekMessage.call( msg, nil, 0, 0, PM_NOREMOVE ) != 0
  end
  
end # module TT::Win32