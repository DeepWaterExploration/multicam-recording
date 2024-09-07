import list_devices
import v4l2
import fcntl
import cameraDataUtils

def fourcc2s(fourcc: int):
    res = ''
    res += chr(fourcc & 0x7f)
    res += chr((fourcc >> 8) & 0x7f)
    res += chr((fourcc >> 16) & 0x7f)
    res += chr((fourcc >> 24) & 0x7f)
    if fourcc & (1 << 31):
        res += '-BE'
    return res

def get_devices():
    devices = list_devices.list_devices()

    setup_devices = {}
    for device in devices:
        setup_devices[device.bus_info] = {
            'name': device.device_name,
            'device_paths': device.device_paths,
            'formats': {}
        }
        for path in device.device_paths:
            setup_devices[device.bus_info]['formats'][path] = {}
            file_object = open(path)
            fd = file_object.fileno()
            for i in range(1000):
                v4l2_fmt = v4l2.v4l2_fmtdesc()
                v4l2_fmt.index = i
                v4l2_fmt.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
                try:
                    fcntl.ioctl(fd, v4l2.VIDIOC_ENUM_FMT, v4l2_fmt)
                except:
                    break

                format_sizes = []
                for j in range(1000):
                    frmsize = v4l2.v4l2_frmsizeenum()
                    frmsize.index = j
                    frmsize.pixel_format = v4l2_fmt.pixelformat
                    try:
                        fcntl.ioctl(fd, v4l2.VIDIOC_ENUM_FRAMESIZES, frmsize)
                    except:
                        break
                    if frmsize.type == v4l2.V4L2_FRMSIZE_TYPE_DISCRETE:
                        format_size = {'width': frmsize.discrete.width, 'height': frmsize.discrete.height, 'intervals': []}
                        for k in range(1000):
                            frmival = v4l2.v4l2_frmivalenum()
                            frmival.index = k
                            frmival.pixel_format = v4l2_fmt.pixelformat
                            frmival.width = frmsize.discrete.width
                            frmival.height = frmsize.discrete.height
                            try:
                                fcntl.ioctl(
                                    fd, v4l2.VIDIOC_ENUM_FRAMEINTERVALS, frmival)
                            except:
                                break
                            if frmival.type == v4l2.V4L2_FRMIVAL_TYPE_DISCRETE:
                                format_size['intervals'].append({'numerator': frmival.discrete.numerator, 'denominator': frmival.discrete.denominator})
                        format_sizes.append(format_size)
                setup_devices[device.bus_info]['formats'][path][cameraDataUtils.fourcc2s(v4l2_fmt.pixelformat)] = format_sizes
    return setup_devices

def get_all_formats():
    setup_devices = get_devices()
    paths = {}
    for device_bus_info, device_info in setup_devices.items():
        
        for path, formats in device_info['formats'].items():
            paths[path] = list(formats.keys())
    return paths