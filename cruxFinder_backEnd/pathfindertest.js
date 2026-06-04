// testPath.js
import { findPath } from './src/utils/PathFinderv2.js';

const dataset =
    {
        "wall": {
            "heightCm": 350,
            "imageWidth": 3213,
            "imageHeight": 5712,
            "angle": "vertical"
        },
        "user": {
            "heightCm": 175,
            "armReachCm": 175,
            "inseamCm": 83,
            "weightKg": 68
        },
        "holds": [
            {
                "id": 0,
                "x": 0.27606598194833487,
                "y": 0.7651435574229691,
                "width": 0.1686896981014628,
                "height": 0.0898109243697479,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "sloper",
                    "size": "l"
                }
            },
            {
                "id": 7,
                "x": 0.5239651416122004,
                "y": 0.8231792717086834,
                "width": 0.16588857765328355,
                "height": 0.05217086834733894,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "sloper",
                    "size": "l"
                }
            },
            {
                "id": 9,
                "x": 0.4584500466853408,
                "y": 0.32204131652661067,
                "width": 0.14254590725178962,
                "height": 0.05304621848739496,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "l"
                }
            },
            {
                "id": 16,
                "x": 0.29551820728291317,
                "y": 0.6061799719887955,
                "width": 0.11858076563958916,
                "height": 0.0467436974789916,
                "isStart": true,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 19,
                "x": 0.39822595704948643,
                "y": 0.42436974789915966,
                "width": 0.1223155929038282,
                "height": 0.04131652661064426,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "l"
                }
            },
            {
                "id": 25,
                "x": 0.3952692187986306,
                "y": 0.8607317927170869,
                "width": 0.06535947712418301,
                "height": 0.02468487394957983,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 27,
                "x": 0.5132275132275133,
                "y": 0.7321428571428571,
                "width": 0.05913476501711796,
                "height": 0.03221288515406162,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 28,
                "x": 0.637410519763461,
                "y": 0.553046218487395,
                "width": 0.06598194833488952,
                "height": 0.025560224089635854,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 33,
                "x": 0.4095860566448802,
                "y": 0.46279761904761907,
                "width": 0.06100217864923747,
                "height": 0.028186274509803922,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 34,
                "x": 0.20868347338935575,
                "y": 0.8920693277310925,
                "width": 0.05259881730469966,
                "height": 0.0313375350140056,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 35,
                "x": 0.46747587924058515,
                "y": 0.36659663865546216,
                "width": 0.04730781201369437,
                "height": 0.028711484593837534,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 37,
                "x": 0.5753190164954871,
                "y": 0.6383053221288515,
                "width": 0.0575785869903517,
                "height": 0.0350140056022409,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 38,
                "x": 0.42172424525365704,
                "y": 0.5525210084033614,
                "width": 0.049797696856520385,
                "height": 0.028011204481792718,
                "isStart": false,
                "isTop": false,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            },
            {
                "id": 90,
                "x": 0.4880174291938998,
                "y": 0.2184873949579832,
                "width": 0.07905384375972611,
                "height": 0.03676470588235294,
                "isStart": false,
                "isTop": true,
                "tags": {
                    "type": "jug",
                    "size": "m"
                }
            }
        ]
    }

const result = findPath(dataset);
console.log(JSON.stringify(result, null, 2));